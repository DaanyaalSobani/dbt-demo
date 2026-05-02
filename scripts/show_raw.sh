#!/usr/bin/env bash
set -euo pipefail

echo "===== raw.customers ====="
docker exec -i dbt-demo-postgres psql -U dbt -d dbt_demo -c "select * from raw.customers order by id;"

echo
echo "===== raw.orders ====="
docker exec -i dbt-demo-postgres psql -U dbt -d dbt_demo -c "select * from raw.orders order by id;"
