-- One row per order_item, enriched with product and order context.
-- Most granular fact view; downstream marts aggregate from here.

with items as (
    select * from {{ ref('stg_order_items') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

products as (
    select * from {{ ref('stg_products') }}
)

select
    i.order_item_id,
    i.order_id,
    o.customer_id,
    o.order_date,
    o.status                  as order_status,
    i.product_id,
    p.product_name,
    p.category,
    i.quantity,
    i.unit_price,
    i.line_total
from items i
join orders o   on o.order_id   = i.order_id
join products p on p.product_id = i.product_id
