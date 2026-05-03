-- Conformed customer dimension: identity + order rollups + behavioral metrics.

with customers as (
    select * from {{ ref('stg_customers') }}
),

orders_summary as (
    select * from {{ ref('int_customer_orders') }}
),

events_summary as (
    select * from {{ ref('int_customer_events') }}
)

select
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.country,
    c.signup_date,

    coalesce(o.order_count, 0)            as order_count,
    coalesce(o.completed_order_count, 0)  as completed_order_count,
    coalesce(o.returned_order_count, 0)   as returned_order_count,
    coalesce(o.gross_order_value, 0)      as gross_order_value,
    o.first_order_date,
    o.most_recent_order_date,

    coalesce(e.event_count, 0)            as event_count,
    coalesce(e.page_views, 0)             as page_views,
    coalesce(e.active_days, 0)            as active_days,
    e.last_seen_at,

    case
        when o.most_recent_order_date is null                          then 'never_purchased'
        when o.most_recent_order_date >= current_date - 30             then 'active'
        when o.most_recent_order_date >= current_date - 90             then 'lapsing'
        else                                                                'dormant'
    end                                   as lifecycle_segment

from customers c
left join orders_summary o using (customer_id)
left join events_summary e using (customer_id)
