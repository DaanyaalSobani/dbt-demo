-- Singular test: returns rows that VIOLATE the assertion.
-- Empty result = test passes. Any row returned = test fails.
-- Note: payments can have NULL amount (data quality bug), so we exclude those here.
select
    payment_id,
    order_id,
    amount
from {{ ref('stg_payments') }}
where amount is not null
  and amount < 0
