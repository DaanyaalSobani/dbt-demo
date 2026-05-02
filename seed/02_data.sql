insert into raw.customers (first_name, last_name, email) values
    ('Alice',   'Nguyen',   'alice@example.com'),
    ('Bob',     'Martinez', 'bob@example.com'),
    ('Carol',   'Singh',    'carol@example.com'),
    ('Devon',   'Okafor',   'devon@example.com'),
    ('Eliza',   'Rossi',    'eliza@example.com');

insert into raw.orders (customer_id, order_date, status, amount) values
    (1, '2026-04-02', 'completed',  49.99),
    (1, '2026-04-15', 'completed',  19.50),
    (2, '2026-04-18', 'shipped',   120.00),
    (3, '2026-04-20', 'completed',   8.75),
    (3, '2026-04-22', 'returned',   22.40),
    (4, '2026-04-25', 'pending',    75.00),
    (5, '2026-04-28', 'completed', 199.99);
