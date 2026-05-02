#!/usr/bin/env bash
set -euo pipefail

echo "===== analytics.customer_orders ====="
docker exec -i dbt-demo-postgres psql -U dbt -d dbt_demo -c "select * from analytics.customer_orders order by customer_id;"

echo
echo "===== analytics.orders_incremental ====="
docker exec -i dbt-demo-postgres psql -U dbt -d dbt_demo -c "select * from analytics.orders_incremental order by order_date, order_id;"
