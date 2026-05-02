-- Equivalent of models/marts/customer_orders.sql
-- Drop-and-recreate, mirrors dbt's `materialized: table` behavior.

create schema if not exists analytics_sp;

create or replace procedure analytics_sp.build_customer_orders()
language plpgsql
as $$
begin
    drop table if exists analytics_sp.customer_orders;

    create table analytics_sp.customer_orders as
    with customers as (
        select
            id           as customer_id,
            first_name,
            last_name,
            email
        from raw.customers
    ),
    orders as (
        select
            id          as order_id,
            customer_id,
            order_date,
            amount
        from raw.orders
    ),
    customer_totals as (
        select
            customer_id,
            count(*)        as order_count,
            sum(amount)     as lifetime_value,
            max(order_date) as most_recent_order
        from orders
        group by customer_id
    )
    select
        c.customer_id,
        c.first_name,
        c.last_name,
        c.email,
        coalesce(t.order_count, 0)    as order_count,
        coalesce(t.lifetime_value, 0) as lifetime_value,
        t.most_recent_order
    from customers c
    left join customer_totals t using (customer_id);

    raise notice 'Built analytics_sp.customer_orders (% rows)',
        (select count(*) from analytics_sp.customer_orders);
end;
$$;
