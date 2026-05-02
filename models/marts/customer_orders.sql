with customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

customer_totals as (
    select
        customer_id,
        count(*)        as order_count,
        sum(amount)     as lifetime_value,
        max(order_date) as most_recent_order
    from orders
    group by customer_id
)

select
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    coalesce(t.order_count, 0)  as order_count,
    coalesce(t.lifetime_value, 0) as lifetime_value,
    t.most_recent_order
from customers c
left join customer_totals t using (customer_id)
