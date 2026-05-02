#!/usr/bin/env bash
set -euo pipefail

DIR="$(dirname "$0")/../stored_procs"

echo "===== Installing procedures ====="
for f in "$DIR"/*.sql; do
    echo "-- $f"
    docker exec -i dbt-demo-postgres psql -U dbt -d dbt_demo -v ON_ERROR_STOP=1 < "$f"
done

echo
echo "===== Calling analytics_sp.build_all() ====="
docker exec -i dbt-demo-postgres psql -U dbt -d dbt_demo -c "call analytics_sp.build_all();"

echo
echo "===== analytics_sp.customer_orders ====="
docker exec -i dbt-demo-postgres psql -U dbt -d dbt_demo -c "select * from analytics_sp.customer_orders order by customer_id;"

echo
echo "===== analytics_sp.orders_incremental ====="
docker exec -i dbt-demo-postgres psql -U dbt -d dbt_demo -c "select * from analytics_sp.orders_incremental order by order_id;"
