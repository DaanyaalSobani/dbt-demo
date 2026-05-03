select
    id           as customer_id,
    first_name,
    last_name,
    email,
    country,
    signup_date,
    created_at
from {{ source('raw', 'customers') }}
