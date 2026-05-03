select
    id          as payment_id,
    order_id,
    method,
    amount,
    paid_at
from {{ source('raw', 'payments') }}
