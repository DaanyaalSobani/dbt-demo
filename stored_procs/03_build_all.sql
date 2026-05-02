-- Orchestrator: equivalent of `dbt build` for our two marts.
-- A real "stored-proc-only" pipeline would also enforce dependency ordering
-- by hand here — dbt does this automatically from ref()/source() calls.

create or replace procedure analytics_sp.build_all()
language plpgsql
as $$
begin
    raise notice '--- build_customer_orders ---';
    call analytics_sp.build_customer_orders();

    raise notice '--- build_orders_incremental ---';
    call analytics_sp.build_orders_incremental();

    raise notice '--- done ---';
end;
$$;
