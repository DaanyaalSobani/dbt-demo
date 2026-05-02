create schema if not exists raw;

create table raw.customers (
    id          integer primary key,
    first_name  text not null,
    last_name   text not null,
    email       text not null,
    created_at  timestamp not null default now()
);

create table raw.orders (
    id           integer primary key,
    customer_id  integer not null references raw.customers(id),
    order_date   date not null,
    status       text not null,
    amount       numeric(10, 2) not null
);
