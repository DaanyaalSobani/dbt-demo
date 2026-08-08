# dbt-demo

A companion repo for my YouTube video about dbt.

> 📺 **Watch the video:** _coming soon — link will go here_

[Look at the data for this demo](https://dbt-test.dsobani.com/pg_data/)

[Explore DBTs generated docs for this project](https://dbt-test.dsobani.com)

## What this repo shows

A side-by-side comparison of two ways to transform data in a Postgres warehouse:

1. **dbt models** — declarative SQL with auto-derived lineage, tests, and materializations.
2. **Stored procedures** — the same logic written as plpgsql, the way many teams do it today.

The goal is to let you run both, query both, and decide for yourself where dbt earns its keep and where the skepticism is fair.

## Prerequisites

- Docker (for the local Postgres)
- Python 3.9+ (for dbt)
- VS Code (recommended — extensions auto-install on first open)

## Quick start

```bash
# 1. Spin up the local Postgres (auto-seeds raw.customers and raw.orders)
docker compose up -d

# 2. Install dbt (>= 1.8 — unit tests need it)
pip install -r requirements.txt

# 3. Build everything
dbt build

# 4. Look at the data
./scripts/show_raw.sh        # source tables
./scripts/show_marts.sh      # dbt-built tables
```

If `dbt debug` complains about `libpq.so.5`, install the system lib:

```bash
sudo apt-get install -y libpq5
```

## What's in the box

| Path | What it is |
| --- | --- |
| [docker-compose.yaml](docker-compose.yaml) | Local Postgres, port `5432`, user/pass `dbt`/`dbt`, db `dbt_demo` |
| [seed/](seed/) | Auto-runs on first container start: creates `raw.customers`, `raw.orders` and inserts a few rows |
| [dbt_project.yml](dbt_project.yml), [profiles.yml](profiles.yml) | Self-contained dbt config (no `~/.dbt/` involvement) |
| [models/staging/](models/staging/) | `stg_customers`, `stg_orders` — views over the raw tables |
| [models/marts/customer_orders.sql](models/marts/customer_orders.sql) | Table mart joining customers and orders |
| [models/marts/orders_incremental.sql](models/marts/orders_incremental.sql) | Incremental table — only processes new orders on each run |
| [tests/](tests/) and `_models.yml` files | Generic + singular data tests on the models |
| `_unit_tests.yml` files, [tests/fixtures/](tests/fixtures/) | Unit tests — model logic checked against fixture rows, no warehouse data |
| [stored_procs/](stored_procs/) | Same business logic written as plpgsql procedures, for the comparison |
| [scripts/](scripts/) | Helper shell scripts (show data, add an order, install procs) |

## Things to try

### 1. See dbt's lineage graph

```bash
dbt docs generate
dbt docs serve
```

Click around the DAG — every `ref()` and `source()` is an edge.

### 2. Watch tests stop a broken pipeline

```bash
# insert a "bad" order — customer 999 doesn't exist
docker exec -i dbt-demo-postgres psql -U dbt -d dbt_demo -c \
  "insert into raw.orders (customer_id, order_date, status, amount) \
   values (999, '2026-01-01', 'completed', 50.00);"

dbt build
```

The `relationships` test on `stg_orders.customer_id` will fail and `customer_orders` will be **skipped** — dbt refuses to build a mart on top of broken data.

### 3. Demo the incremental model

```bash
dbt run --select orders_incremental                # initial build
./scripts/add_order.sh 3 99.50                     # insert one new order
dbt run --select orders_incremental                # only the new row gets a fresh loaded_at
./scripts/show_marts.sh                            # confirm
dbt run --select orders_incremental --full-refresh # rebuild from scratch
```

### 4. Use dbt's graph operators

```bash
dbt run --select customer_orders         # just this one
dbt run --select +customer_orders        # this AND its upstream
dbt run --select customer_orders+        # this AND its downstream
dbt run --select staging.*               # everything in the staging folder
```

### 5. Compare to stored procedures

```bash
./scripts/run_stored_procs.sh
```

This installs and calls the equivalent plpgsql in the `analytics_sp` schema. Diff a dbt model against its stored-proc counterpart and notice how much of the proc is boilerplate (drop/create, exception handling, manual incremental logic) vs. the dbt model which is mostly just the SELECT.

### 6. Unit test a model against fake rows (dbt >= 1.8)

Data tests answer "is the data in my warehouse OK?". **Unit tests** answer "is the
SQL I wrote correct?" — they feed hand-written rows into a model, run it, and
compare the output to an expected result. No warehouse data is read.

```bash
dbt test --select test_type:unit          # all three
dbt test --select fct_orders,test_type:unit
```

The tests live in [models/marts/_unit_tests.yml](models/marts/_unit_tests.yml) and
[models/intermediate/_unit_tests.yml](models/intermediate/_unit_tests.yml).

**How it works.** Each `ref()`/`source()` in the model is replaced by a CTE built
from your fixture rows, and the model's own SQL is dropped in underneath
unchanged. Run the command above and look at the compiled result:

```bash
cat target/compiled/dbt_demo/models/intermediate/_unit_tests.yml/models/intermediate/test_int_payments_per_order_ignores_null_amounts.sql
```

```sql
with __dbt__cte__stg_payments as (
-- Fixture for stg_payments
select cast('1' as integer) as "payment_id", ..., cast('25.00' as numeric(10,2)) as "amount", ...
union all
select cast('2' as integer) as "payment_id", ..., cast(null   as numeric(10,2)) as "amount", ...
...
)
select
    order_id,
    count(*)                                as payment_count,
    sum(coalesce(amount, 0))                as total_paid,
    count(*) filter (where amount is null)  as null_amount_payments,
    ...
from __dbt__cte__stg_payments
group by order_id
```

That's the whole trick — a CTE swap. The model file is never edited, and because
the fixtures are literals the test runs on an empty database.

Fixtures come in three flavours, all three are used here:

| Format | Where | Why |
| --- | --- | --- |
| inline dicts | `stg_orders` input, and every `expect:` block | most readable; omitted columns default to NULL |
| `format: csv` + `fixture:` | [tests/fixtures/stg_payments__mixed_nulls.csv](tests/fixtures/stg_payments__mixed_nulls.csv) | good for wide tables; an empty cell means NULL |
| `format: sql` | the `int_*` inputs in `fct_orders` | see the gotcha below |

**Gotchas worth knowing:**

- **Ephemeral inputs need `format: sql`.** For dict and csv fixtures dbt
  introspects the real relation to learn each input's column types. Our
  `intermediate` models are `+materialized: ephemeral`, so no relation exists and
  you get `Not able to get columns for unit test '...' because the relation
  doesn't exist`. A `format: sql` fixture declares its own types
  (`0::numeric as line_total`) and skips introspection entirely.
- **Decimal scale matters.** Expected and actual are compared as rendered
  strings, and YAML reads `100.00` as the float `100.0`, which won't match a
  `numeric(10,2)` result. Quote it: `header_vs_lines_diff: '100.00'`.
- **`dbt build` runs unit tests before the model is built**, but skips them if
  anything upstream fails — this repo's deliberately-failing
  `assert_no_negative_order_amounts` does exactly that. Use
  `dbt test --select test_type:unit` to run them on their own.

To watch one fail, flip a `coalesce(..., 0)` to plain `null` in
[fct_orders.sql](models/marts/fct_orders.sql) and re-run — dbt prints a
cell-level diff of expected vs actual.

### 7. Reset everything

```bash
docker compose down -v       # wipes the volume — re-runs the seed scripts
docker compose up -d
dbt build
```

## How dbt finds this project

When you run `dbt build` from the repo root, dbt has to figure out two things: "what project am I working with?" and "how do I connect to the database?" Here's what happens:

1. **Project detection** — dbt walks up from the current directory looking for a `dbt_project.yml`. The presence of [dbt_project.yml](dbt_project.yml) at the repo root is what turns this folder into a dbt project. It tells dbt the project name (`dbt_demo`), where to find models, what materializations to default to, and which **profile** to use.

2. **Profile resolution** — the profile name from `dbt_project.yml` (here, `dbt_demo`) has to be defined in a `profiles.yml` somewhere. By default dbt checks `~/.dbt/profiles.yml` (a system-wide file in your home directory) — this is what `dbt init` modifies and why most tutorials end up with credentials scattered across your machine.

   **Since dbt-core 1.5+, dbt also checks for a `profiles.yml` next to `dbt_project.yml`.** Because we ship [profiles.yml](profiles.yml) in the repo root, dbt picks it up automatically — no `~/.dbt/` involvement, no `--profiles-dir` flag, no environment variable juggling. Clone the repo, run `dbt build`, done.

This is why the project is fully self-contained: everything dbt needs to identify the project AND connect to the warehouse lives inside this directory.

## Connecting from VS Code

Open the project in VS Code and accept the recommended extensions ([.vscode/extensions.json](.vscode/extensions.json)). The PostgreSQL connection profile is pre-baked in [.vscode/settings.json](.vscode/settings.json), so a `dbt-demo (local)` connection appears in the PostgreSQL sidebar — no manual setup.

## A note on the credentials

User `dbt` / password `dbt` / database `dbt_demo` are committed deliberately because this is a demo. **Don't reuse this pattern in real projects.** Use environment variables and a secret manager.
