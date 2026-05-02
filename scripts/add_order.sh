#!/usr/bin/env bash
set -euo pipefail

# Inserts a single new order — useful for demoing incremental models.
# Usage: ./scripts/add_order.sh [customer_id] [amount]

CUSTOMER_ID="${1:-2}"
AMOUNT="${2:-42.00}"
TODAY="$(date +%F)"

docker exec -i dbt-demo-postgres psql -U dbt -d dbt_demo -c \
  "insert into raw.orders (customer_id, order_date, status, amount)
   values (${CUSTOMER_ID}, '${TODAY}', 'completed', ${AMOUNT})
   returning *;"
