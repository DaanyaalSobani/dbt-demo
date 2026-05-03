-- One row per order with computed line totals and payment rollups.
-- Note: header_amount comes from the source; computed_total comes from line items.
-- A mismatch between the two is a classic data-quality gotcha.

with orders as (
    select * from {{ ref('stg_orders') }}
),

line_totals as (
    select
        order_id,
        sum(line_total) as computed_total,
        count(*)        as item_count
    from {{ ref('int_orders_with_items') }}
    group by order_id
),

payments as (
    select * from {{ ref('int_payments_per_order') }}
)

select
    o.order_id,
    o.customer_id,
    o.order_date,
    o.status,
    o.header_amount,
    coalesce(l.computed_total, 0)      as computed_total,
    coalesce(l.item_count, 0)          as item_count,
    coalesce(p.payment_count, 0)       as payment_count,
    coalesce(p.total_paid, 0)          as total_paid,
    coalesce(p.null_amount_payments, 0) as null_amount_payments,
    -- Difference between source-of-truth header and recomputed line totals.
    o.header_amount - coalesce(l.computed_total, 0) as header_vs_lines_diff
from orders o
left join line_totals l on l.order_id = o.order_id
left join payments p   on p.order_id = o.order_id
