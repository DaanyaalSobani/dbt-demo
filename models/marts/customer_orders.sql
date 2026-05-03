-- Backwards-compat thin wrapper over dim_customers.
-- Kept so the original demo / docs still work; in a real project you'd
-- pick one or the other.

select
    customer_id,
    first_name,
    last_name,
    email,
    order_count,
    gross_order_value as lifetime_value,
    most_recent_order_date as most_recent_order
from {{ ref('dim_customers') }}
