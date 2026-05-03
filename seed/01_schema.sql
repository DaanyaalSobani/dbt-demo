create schema if not exists raw;

create table raw.customers (
    id          integer generated always as identity primary key,
    first_name  text not null,
    last_name   text not null,
    email       text not null,
    country     text,
    signup_date date not null default current_date,
    created_at  timestamp not null default now()
);

create table raw.products (
    id          integer generated always as identity primary key,
    sku         text not null,
    name        text not null,
    category    text not null,
    price       numeric(10, 2) not null,
    is_active   boolean not null default true
);

create table raw.orders (
    id           integer generated always as identity primary key,
    customer_id  integer not null references raw.customers(id),
    order_date   date not null,
    status       text not null,
    -- amount is denormalized header total; fact tables will recompute from items
    amount       numeric(10, 2) not null,
    updated_at   timestamp not null default now()
);

create table raw.order_items (
    id           integer generated always as identity primary key,
    order_id     integer not null references raw.orders(id),
    product_id   integer not null references raw.products(id),
    quantity     integer not null,
    unit_price   numeric(10, 2) not null
);

create table raw.payments (
    id           integer generated always as identity primary key,
    order_id     integer not null references raw.orders(id),
    method       text not null,
    amount       numeric(10, 2),  -- intentionally nullable to demo data quality
    paid_at      timestamp not null default now()
);

create table raw.events (
    id           bigint generated always as identity primary key,
    customer_id  integer references raw.customers(id),
    event_type   text not null,
    event_at     timestamp not null,
    page         text
);
