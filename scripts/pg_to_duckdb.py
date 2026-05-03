"""Copy raw.* tables from Postgres into a local DuckDB file.

Usage:
    python scripts/pg_to_duckdb.py [--full-refresh]

Requires: pip install duckdb
DuckDB pulls the postgres extension on first run.
"""

import argparse
import os
import time

import duckdb

PG_DSN = os.environ.get(
    "PG_DSN",
    "host=localhost port=5432 dbname=dbt_demo user=dbt password=dbt",
)
DUCKDB_PATH = os.environ.get("DUCKDB_PATH", "warehouse.duckdb")

TABLES = [
    ("raw", "customers", "id"),
    ("raw", "products", "id"),
    ("raw", "orders", "id"),
    ("raw", "order_items", "id"),
    ("raw", "payments", "id"),
    ("raw", "events", "id"),
]


def main(full_refresh: bool) -> None:
    con = duckdb.connect(DUCKDB_PATH)
    con.execute("install postgres; load postgres;")
    con.execute(f"attach '{PG_DSN}' as pg (type postgres, read_only)")
    con.execute("create schema if not exists raw")

    for schema, table, pk in TABLES:
        fq = f"raw.{table}"
        src = f"pg.{schema}.{table}"
        exists = con.execute(
            "select 1 from information_schema.tables "
            "where table_schema = 'raw' and table_name = ?",
            [table],
        ).fetchone()

        start = time.perf_counter()
        if full_refresh or not exists:
            con.execute(f"create or replace table {fq} as select * from {src}")
            mode = "full"
        else:
            max_id = con.execute(f"select coalesce(max({pk}), 0) from {fq}").fetchone()[0]
            con.execute(
                f"insert into {fq} select * from {src} where {pk} > {max_id}"
            )
            mode = f"incremental (>{max_id})"

        rows = con.execute(f"select count(*) from {fq}").fetchone()[0]
        elapsed = time.perf_counter() - start
        print(f"{fq:<20} {mode:<22} {rows:>10,} rows  {elapsed:6.2f}s")

    con.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--full-refresh", action="store_true")
    args = parser.parse_args()
    main(args.full_refresh)
