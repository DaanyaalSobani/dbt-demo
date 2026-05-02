insert into raw.customers (id, first_name, last_name, email) values
    (1, 'Alice',   'Nguyen',   'alice@example.com'),
    (2, 'Bob',     'Martinez', 'bob@example.com'),
    (3, 'Carol',   'Singh',    'carol@example.com'),
    (4, 'Devon',   'Okafor',   'devon@example.com'),
    (5, 'Eliza',   'Rossi',    'eliza@example.com');

insert into raw.orders (id, customer_id, order_date, status, amount) values
    (101, 1, '2026-04-02', 'completed',  49.99),
    (102, 1, '2026-04-15', 'completed',  19.50),
    (103, 2, '2026-04-18', 'shipped',   120.00),
    (104, 3, '2026-04-20', 'completed',   8.75),
    (105, 3, '2026-04-22', 'returned',   22.40),
    (106, 4, '2026-04-25', 'pending',    75.00),
    (107, 5, '2026-04-28', 'completed', 199.99);
