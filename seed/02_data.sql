-- Synthetic data generated with generate_series so it scales easily.
-- Tweak the constants at the top to make it bigger/smaller.

-- ===== Customers =====
insert into raw.customers (first_name, last_name, email, country, signup_date)
select
    (array['Alice','Bob','Carol','Devon','Eliza','Frank','Grace','Hank','Iris','Jasper',
           'Kira','Liam','Maya','Noah','Olive','Priya','Quinn','Rohan','Sara','Theo'])
        [1 + (i % 20)],
    (array['Nguyen','Martinez','Singh','Okafor','Rossi','Park','Kim','Patel','Garcia','Smith'])
        [1 + (i % 10)],
    'user' || i || '@example.com',
    (array['US','UK','DE','FR','CA','AU','IN','BR','JP','MX'])[1 + (i % 10)],
    current_date - ((i * 7) % 365)
from generate_series(1, 50) as i;

-- ===== Products =====
insert into raw.products (sku, name, category, price, is_active)
select
    'SKU-' || lpad(i::text, 5, '0'),
    (array['Widget','Gadget','Gizmo','Doodad','Thingamajig','Whatsit','Doohickey'])[1 + (i % 7)]
        || ' ' || (array['Pro','Mini','Max','Lite','Plus','Air','Edge'])[1 + ((i / 7) % 7)],
    (array['Electronics','Apparel','Home','Sports','Books'])[1 + (i % 5)],
    round((10 + (i * 13) % 490)::numeric, 2),
    (i % 11 != 0)  -- ~9% inactive
from generate_series(1, 80) as i;

-- ===== Orders ===== (500 orders across the last year)
insert into raw.orders (customer_id, order_date, status, amount)
select
    1 + (i * 7) % 50,                                    -- customer_id
    current_date - ((i * 3) % 365),                      -- order_date
    (array['completed','completed','completed','completed','shipped','pending','returned','cancelled'])
        [1 + (i % 8)],                                   -- weighted toward completed
    round((20 + (i * 17) % 480)::numeric, 2)             -- placeholder header amount
from generate_series(1, 500) as i;

-- ===== Order Items ===== (1-5 items per order, ~1500 rows)
insert into raw.order_items (order_id, product_id, quantity, unit_price)
select
    o.id,
    1 + ((o.id * 11 + i) % 80),                          -- product_id
    1 + ((o.id + i) % 4),                                -- quantity 1..4
    (select price from raw.products where id = 1 + ((o.id * 11 + i) % 80))
from raw.orders o
cross join lateral generate_series(1, 1 + (o.id % 5)) as i;

-- ===== Payments ===== (most orders 1 payment, ~10% split into 2)
insert into raw.payments (order_id, method, amount, paid_at)
select
    o.id,
    (array['card','card','card','paypal','bank_transfer'])[1 + (o.id % 5)],
    case
        when o.id % 13 = 0 then null                     -- ~7% NULL — data quality bug
        else round(o.amount * 0.7, 2)
    end,
    o.order_date + interval '1 hour'
from raw.orders o
where o.status not in ('cancelled')

union all

-- second payment for ~10% of orders (split payments)
select
    o.id,
    'card',
    round(o.amount * 0.3, 2),
    o.order_date + interval '2 hours'
from raw.orders o
where o.id % 10 = 0
  and o.status not in ('cancelled');

-- ===== Events ===== (5-10 events per customer, ~3000 rows)
insert into raw.events (customer_id, event_type, event_at, page)
select
    1 + (i % 50),
    (array['page_view','page_view','page_view','add_to_cart','checkout','purchase'])
        [1 + (i % 6)],
    now() - ((i * 17) % (60 * 60 * 24 * 30) || ' seconds')::interval,
    (array['/home','/products','/product/widget','/cart','/checkout','/account'])[1 + (i % 6)]
from generate_series(1, 3000) as i;

-- ===== Intentional gotchas for the demo =====

-- 1. A customer with a duplicate email — breaks a `unique` test on email
insert into raw.customers (first_name, last_name, email, country)
values ('Alice', 'Duplicate', 'user1@example.com', 'US');

-- 2. An order with a status not in our accepted_values list
insert into raw.orders (customer_id, order_date, status, amount)
values (1, current_date, 'totally_made_up_status', 99.99);

-- 3. A negative-amount payment (singular test will catch this)
insert into raw.payments (order_id, method, amount, paid_at)
values (1, 'refund', -50.00, now());
