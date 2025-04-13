-- Amazon Treasure Hunt Analytics Project
-- Author: Neha Gaikwad


-- 1. Schema Creation
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS sales CASCADE;

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    price DECIMAL(10, 2),
    seller_id INT
);

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    region VARCHAR(100),
    purchase_history TEXT
);

CREATE TABLE reviews (
    review_id SERIAL PRIMARY KEY,
    product_id INT REFERENCES products(product_id),
    customer_id INT REFERENCES customers(customer_id),
    rating DECIMAL(2, 1) CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    review_date DATE
);

CREATE TABLE sales (
    sale_id SERIAL PRIMARY KEY,
    product_id INT REFERENCES products(product_id),
    sale_date DATE,
    quantity_sold INT,
    total_amount DECIMAL(10, 2)
);

-- 2. Sample Data Insertion (for demo purposes)
INSERT INTO products (product_name, category, price, seller_id) VALUES
('Eco-Friendly Water Bottle', 'Home & Kitchen', 19.99, 101),
('Wireless Earbuds Pro', 'Electronics', 49.99, 102),
('Organic Tea Sampler', 'Grocery', 15.49, 103),
('Smart LED Bulb', 'Home & Kitchen', 24.99, 101),
('Retro Board Game', 'Toys & Games', 29.99, 104);

INSERT INTO customers (region, purchase_history) VALUES
('North America', 'Electronics, Home'),
('Europe', 'Grocery, Toys'),
('Asia', 'Home, Electronics'),
('North America', 'Grocery');

INSERT INTO reviews (product_id, customer_id, rating, review_text, review_date) VALUES
(1, 1, 4.8, 'Love this bottle! So durable.', '2025-03-01'),
(1, 2, 4.5, 'Great design, amazing quality.', '2025-03-15'),
(2, 3, 4.9, 'Sound is incredible!', '2025-02-20'),
(3, 4, 4.2, 'Tasty, but pricey.', '2025-03-10'),
(4, 1, 4.7, 'Super bright, love it!', '2025-03-05');

INSERT INTO sales (product_id, sale_date, quantity_sold, total_amount) VALUES
(1, '2025-02-01', 50, 999.50),
(1, '2025-03-01', 70, 1399.30),
(2, '2025-02-15', 30, 1499.70),
(2, '2025-03-15', 45, 2249.55),
(3, '2025-03-01', 20, 309.80),
(4, '2025-03-10', 25, 624.75);

-- 3. Query 1: Treasure Score Calculation
-- Identifies top "treasure" products with high ratings, low review counts, competitive pricing, and rising sales.
WITH ProductMetrics AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.category,
        p.price,
        AVG(r.rating) AS avg_rating,
        COUNT(r.review_id) AS review_count,
        AVG(s.quantity_sold) AS avg_sales,
        COALESCE(
            AVG(s.quantity_sold) / NULLIF(LAG(AVG(s.quantity_sold)) OVER (
                PARTITION BY p.product_id 
                ORDER BY DATE_TRUNC('month', s.sale_date)
            ), 0) - 1, 
            0
        ) AS sales_growth
    FROM products p
    LEFT JOIN reviews r ON p.product_id = r.product_id
    LEFT JOIN sales s ON p.product_id = s.product_id
    WHERE s.sale_date >= CURRENT_DATE - INTERVAL '3 months'
    GROUP BY p.product_id, p.product_name, p.category, p.price
),
CategoryPricing AS (
    SELECT 
        category,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price) AS median_price
    FROM products
    GROUP BY category
)
SELECT 
    pm.product_id,
    pm.product_name,
    pm.category,
    ROUND(pm.avg_rating, 2) AS avg_rating,
    pm.review_count,
    ROUND(pm.avg_sales, 2) AS avg_sales,
    ROUND(pm.sales_growth, 2) AS sales_growth,
    pm.price,
    cp.median_price,
    ROUND(
        CASE 
            WHEN pm.avg_rating > 4.5 
                 AND pm.review_count < 50 
                 AND pm.price BETWEEN cp.median_price * 0.9 AND cp.median_price * 1.1 
                 AND pm.sales_growth > 0.2 
            THEN (pm.avg_rating * 0.4 + pm.sales_growth * 0.3 + (1 - pm.review_count / 50.0) * 0.3) * 100
            ELSE 0
        END, 
        2
    ) AS treasure_score
FROM ProductMetrics pm
JOIN CategoryPricing cp ON pm.category = cp.category
WHERE pm.avg_rating IS NOT NULL
ORDER BY treasure_score DESC
LIMIT 10;

-- 4. Query 2: Sentiment Pulse
-- Flags products with a surge in positive sentiment based on recent reviews.
SELECT 
    p.product_id,
    p.product_name,
    COUNT(r.review_id) AS recent_reviews,
    ROUND(AVG(r.rating), 2) AS avg_recent_rating,
    SUM(CASE 
        WHEN r.review_text ILIKE '%love%' OR r.review_text ILIKE '%amazing%' 
        THEN 1 
        ELSE 0 
    END) AS positive_mentions
FROM products p
JOIN reviews r ON p.product_id = r.product_id
WHERE r.review_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY p.product_id, p.product_name
HAVING COUNT(r.review_id) > 1 AND AVG(r.rating) > 4
ORDER BY positive_mentions DESC, avg_recent_rating DESC
LIMIT 5;

-- 5. Query 3: Seasonal Spotlight
-- Highlights top categories by month to predict seasonal trends.
SELECT 
    p.category,
    EXTRACT(MONTH FROM s.sale_date) AS sale_month,
    SUM(s.quantity_sold) AS total_units_sold,
    ROUND(SUM(s.total_amount), 2) AS total_revenue,
    RANK() OVER (
        PARTITION BY EXTRACT(MONTH FROM s.sale_date) 
        ORDER BY SUM(s.quantity_sold) DESC
    ) AS category_rank
FROM products p
JOIN sales s ON p.product_id = s.product_id
WHERE s.sale_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY p.category, EXTRACT(MONTH FROM s.sale_date)
HAVING SUM(s.quantity_sold) > 10
ORDER BY sale_month, total_units_sold DESC
LIMIT 10;

-- 6. Indexes for Performance Optimization
CREATE INDEX idx_reviews_product_id ON reviews(product_id);
CREATE INDEX idx_sales_product_id ON sales(product_id);
CREATE INDEX idx_sales_date ON sales(sale_date);

-- End of Amazon Treasure Hunt Analytics
