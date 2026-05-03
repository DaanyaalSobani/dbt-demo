-- Singular test: returns rows that VIOLATE the assertion.
-- Empty result = test passes. Any row returned = test fails.
select
    order_id,
    amount
from {{ ref('stg_orders') }}
where amount < 0
