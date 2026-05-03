select
    id           as order_id,
    customer_id,
    order_date,
    status,
    amount       as header_amount,
    updated_at
from {{ source('raw', 'orders') }}
