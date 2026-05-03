-- Collapses 0..N payments into one row per order.
-- Notice the COALESCE — raw.payments has nullable amounts (intentional gotcha).

select
    order_id,
    count(*)                          as payment_count,
    sum(coalesce(amount, 0))          as total_paid,
    count(*) filter (where amount is null) as null_amount_payments,
    min(paid_at)                      as first_paid_at,
    max(paid_at)                      as last_paid_at
from {{ ref('stg_payments') }}
group by order_id
