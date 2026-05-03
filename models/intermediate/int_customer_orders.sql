-- Order-level aggregates per customer.

select
    customer_id,
    count(*)                                     as order_count,
    count(*) filter (where status = 'completed') as completed_order_count,
    count(*) filter (where status = 'returned')  as returned_order_count,
    sum(header_amount)                           as gross_order_value,
    min(order_date)                              as first_order_date,
    max(order_date)                              as most_recent_order_date
from {{ ref('stg_orders') }}
group by customer_id
