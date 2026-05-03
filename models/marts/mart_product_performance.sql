-- Product-level sales rollup, joined back to the product dimension.
-- Highlights how easy fan-in is once you have a clean intermediate layer.

with products as (
    select * from {{ ref('stg_products') }}
),

sales as (
    select
        product_id,
        sum(quantity)        as units_sold,
        sum(line_total)      as gross_sales,
        count(distinct order_id)   as order_count,
        count(distinct customer_id) as buyer_count
    from {{ ref('int_orders_with_items') }}
    group by product_id
)

select
    p.product_id,
    p.sku,
    p.product_name,
    p.category,
    p.price,
    p.is_active,
    coalesce(s.units_sold, 0)   as units_sold,
    coalesce(s.gross_sales, 0)  as gross_sales,
    coalesce(s.order_count, 0)  as order_count,
    coalesce(s.buyer_count, 0)  as buyer_count
from products p
left join sales s using (product_id)
