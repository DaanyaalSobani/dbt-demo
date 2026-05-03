-- Behavioral aggregates per customer from the events stream.

select
    customer_id,
    count(*)                                                  as event_count,
    count(*) filter (where event_type = 'page_view')          as page_views,
    count(*) filter (where event_type = 'add_to_cart')        as cart_adds,
    count(*) filter (where event_type = 'checkout')           as checkouts,
    count(*) filter (where event_type = 'purchase')           as purchase_events,
    count(distinct date_trunc('day', event_at))               as active_days,
    max(event_at)                                             as last_seen_at
from {{ ref('stg_events') }}
where customer_id is not null
group by customer_id
