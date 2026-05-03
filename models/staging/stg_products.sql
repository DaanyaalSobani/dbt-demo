select
    id          as product_id,
    sku,
    name        as product_name,
    category,
    price,
    is_active
from {{ source('raw', 'products') }}
