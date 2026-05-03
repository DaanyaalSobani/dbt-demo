select
    id          as event_id,
    customer_id,
    event_type,
    event_at,
    page
from {{ source('raw', 'events') }}
