SELECT *
FROM analytics.customer_orders;


insert into raw.orders (customer_id, order_date, status, amount) values
    (1, '2026-05-02', 'completed', 64.25);
    
