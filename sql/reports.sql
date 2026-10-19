-- sql/reports.sql

-- a) Order totals
-- Expected: total_orders = 180, total_revenue = 99860.20, avg_order_value = 554.78.
-- Output: 180 | 99860.2 | 554.78
SELECT
    COUNT(*) AS total_orders,
    ROUND(SUM(o.quantity * p.price * (1 - COALESCE(o.discount_pct, 0) / 100.0)), 2) AS total_revenue,
    ROUND(AVG(o.quantity * p.price * (1 - COALESCE(o.discount_pct, 0) / 100.0)), 2) AS avg_order_value
FROM orders o
JOIN products p ON o.product_id = p.product_id;


-- b) COUNT(*) vs COUNT(column)
-- Expected: (180, 165, 15)
-- Output: 180 | 165 | 15
SELECT
    COUNT(*) AS total_rows,
    COUNT(rating) AS rated_orders,
    COUNT(*) - COUNT(rating) AS unrated_orders
FROM orders;


-- c) LEFT JOIN with a genuine zero-match row
-- Expected: Both queries return exactly one row — C045, Vihaan.
-- Output (Query 1): C045 | Vihaan
SELECT c.customer_id, c.name
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
HAVING COUNT(o.order_id) = 0;

-- Output (Query 2): C045 | Vihaan
SELECT customer_id, name
FROM customers
WHERE customer_id NOT IN (
    SELECT DISTINCT customer_id FROM orders WHERE customer_id IS NOT NULL
);


-- d) GROUP BY + HAVING
-- Expected: Jaipur (19, 8, 42.1), Lucknow (49, 15, 30.6), Bangalore (33, 8, 24.2)
-- Output:
-- Jaipur    | 19 | 8  | 42.1
-- Lucknow   | 49 | 15 | 30.6
-- Bangalore | 33 | 8  | 24.2
SELECT
    c.city,
    COUNT(o.order_id) AS total_orders,
    SUM(o.returned) AS returned_orders,
    ROUND(SUM(o.returned) * 100.0 / COUNT(o.order_id), 1) AS return_rate_pct
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.city
HAVING return_rate_pct > 20
ORDER BY return_rate_pct DESC;


-- e) Ranking with ORDER BY + LIMIT/OFFSET
-- Expected Top 5: C043 Reyansh 12920.00, C026 Isha 8371.60, C008 Meera 4564.60, C011 Arjun 4111.00, C042 Sanya 3785.00
-- Tie-break reasoning: `customer_id ASC` ensures deterministic ordering if two customers have the exact same total_spend.
-- Output (Query 1):
-- C043 | Reyansh | 12920.0
-- C026 | Isha    | 8371.6
-- C008 | Meera   | 4564.6
-- C011 | Arjun   | 4111.0
-- C042 | Sanya   | 3785.0
SELECT
    c.customer_id,
    c.name,
    ROUND(SUM(o.quantity * p.price * (1 - COALESCE(o.discount_pct, 0) / 100.0)), 2) AS total_spend
FROM orders o
JOIN products p ON o.product_id = p.product_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.name
ORDER BY total_spend DESC, c.customer_id ASC
LIMIT 5;

-- Output (Query 2):
-- C008 | Meera   | 4564.6
-- C011 | Arjun   | 4111.0
-- C042 | Sanya   | 3785.0
SELECT
    c.customer_id,
    c.name,
    ROUND(SUM(o.quantity * p.price * (1 - COALESCE(o.discount_pct, 0) / 100.0)), 2) AS total_spend
FROM orders o
JOIN products p ON o.product_id = p.product_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.name
ORDER BY total_spend DESC, c.customer_id ASC
LIMIT 3 OFFSET 2;


-- f) Three-table JOIN with GROUP BY
-- Expected: Haircare (54, 44956.10), Skincare (60, 27346.00), Babycare (30, 16805.00), PersonalCare (36, 10753.10)
-- Output:
-- Haircare     | 54 | 44956.1
-- Skincare     | 60 | 27346.0
-- Babycare     | 30 | 16805.0
-- PersonalCare | 36 | 10753.1
SELECT
    p.category,
    COUNT(o.order_id) AS order_count,
    ROUND(SUM(o.quantity * p.price * (1 - COALESCE(o.discount_pct, 0) / 100.0)), 2) AS category_revenue
FROM orders o
JOIN products p ON o.product_id = p.product_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY p.category
ORDER BY category_revenue DESC;


-- g) LIKE pattern match
-- Expected: exactly 10 rows.
-- Output: 10 rows (C001, C003, C004, C011, C021, C030, C031, C036, C041, C044)
SELECT customer_id, name, city, city_tier, signup_date, acquisition_source
FROM customers
WHERE name LIKE 'A%';


-- h) DISTINCT
-- Expected: exactly 4 values — Ad, Organic, Referral, Social.
-- Output: Ad | Organic | Referral | Social
SELECT DISTINCT acquisition_source
FROM customers
ORDER BY acquisition_source;


-- i) ALTER TABLE + UPDATE with CASE
-- Output: Gold | 28  and  Silver | 17
ALTER TABLE customers ADD COLUMN loyalty_tier VARCHAR(10);

UPDATE customers
SET loyalty_tier = CASE WHEN city_tier = 1 THEN 'Gold' ELSE 'Silver' END;

SELECT loyalty_tier, COUNT(*) AS tier_count
FROM customers
GROUP BY loyalty_tier;
