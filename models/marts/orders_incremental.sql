{{
  config(
    materialized='incremental',
    unique_key='order_id'
  )
}}

select
    order_id,
    customer_id,
    order_date,
    status,
    header_amount,
    current_timestamp as loaded_at
from {{ ref('stg_orders') }}

{% if is_incremental() %}
    where order_id > (select coalesce(max(order_id), 0) from {{ this }})
{% endif %}
