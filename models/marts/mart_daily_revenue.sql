-- Daily revenue rollup. Useful for the "show off a chart in Metabase" demo.

select
    order_date,
    count(*)                                              as order_count,
    count(*) filter (where status = 'completed')          as completed_orders,
    sum(computed_total)                                   as gross_revenue,
    sum(computed_total) filter (where status = 'completed') as net_revenue,
    sum(total_paid)                                       as total_paid,
    avg(computed_total)                                   as avg_order_value
from {{ ref('fct_orders') }}
group by order_date
order by order_date
