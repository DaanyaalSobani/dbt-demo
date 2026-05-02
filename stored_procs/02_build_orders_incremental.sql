-- Equivalent of models/marts/orders_incremental.sql
-- Mirrors dbt's `materialized: incremental` with unique_key='order_id'.
-- First call creates and fully populates the table; subsequent calls
-- only merge rows with order_id greater than the current max.

create or replace procedure analytics_sp.build_orders_incremental()
language plpgsql
as $$
declare
    last_id integer;
begin
    -- First-run: create the table if it doesn't exist
    if to_regclass('analytics_sp.orders_incremental') is null then
        create table analytics_sp.orders_incremental (
            order_id     integer primary key,
            customer_id  integer not null,
            order_date   date not null,
            status       text not null,
            amount       numeric(10, 2) not null,
            loaded_at    timestamp not null default now()
        );
        last_id := 0;
        raise notice 'Created analytics_sp.orders_incremental (first run).';
    else
        select coalesce(max(order_id), 0) into last_id
        from analytics_sp.orders_incremental;
    end if;

    -- Merge new rows (insert-or-update on conflict)
    insert into analytics_sp.orders_incremental
        (order_id, customer_id, order_date, status, amount, loaded_at)
    select
        id,
        customer_id,
        order_date,
        status,
        amount,
        now()
    from raw.orders
    where id > last_id
    on conflict (order_id) do update set
        customer_id = excluded.customer_id,
        order_date  = excluded.order_date,
        status      = excluded.status,
        amount      = excluded.amount,
        loaded_at   = excluded.loaded_at;

    raise notice 'analytics_sp.orders_incremental now has % rows.',
        (select count(*) from analytics_sp.orders_incremental);
end;
$$;
