CREATE SCHEMA retail_supply_chain; -- creating DB
USE retail_supply_chain;
CREATE TABLE supply_chain ( -- creating table
    row_id INT PRIMARY KEY,
    order_id VARCHAR(20),
    order_date DATE,
    ship_date DATE,
    ship_mode VARCHAR(20),
    customer_id VARCHAR(20),
    customer_name VARCHAR(100),
    segment VARCHAR(20),
    country VARCHAR(50),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(10),
    region VARCHAR(20),
    sales_rep VARCHAR(100),
    product_id VARCHAR(20),
    category VARCHAR(30),
    sub_category VARCHAR(30),
    product_name VARCHAR(200),
    returned VARCHAR(5),
    sales DECIMAL(10,4),
    quantity INT,
    discount DECIMAL(4,2),
    profit DECIMAL(10,4)
);
-- loadiing data into table
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/10.-Retail-Supply-Chain-Sales-Analysis_Challenge-10.csv' 
INTO TABLE supply_chain
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(row_id, order_id, @order_date_raw, @ship_date_raw, ship_mode, customer_id, customer_name,
 segment, country, city, state, postal_code, region, sales_rep, product_id, category,
 sub_category, product_name, returned, sales, quantity, discount, profit)
SET order_date = STR_TO_DATE(@order_date_raw, '%c/%e/%Y'),
    ship_date  = STR_TO_DATE(@ship_date_raw, '%c/%e/%Y');
SELECT * FROM supply_chain;

-- DATA NORMALIZATION
-- Customers Table
CREATE TABLE customers (
    customer_id   VARCHAR(20) PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    segment       VARCHAR(20) NOT NULL
);
INSERT INTO customers (customer_id, customer_name, segment)
SELECT DISTINCT customer_id, customer_name, segment
FROM supply_chain;

-- Products Table
CREATE TABLE products (
    product_key   INT AUTO_INCREMENT PRIMARY KEY,
    product_id    VARCHAR(20) NOT NULL,
    product_name  VARCHAR(200) NOT NULL,
    category      VARCHAR(30) NOT NULL,
    sub_category  VARCHAR(30) NOT NULL,
    UNIQUE KEY uq_product (product_id, product_name)
);
INSERT INTO products (product_id, product_name, category, sub_category)
SELECT DISTINCT product_id, product_name, category, sub_category
FROM supply_chain;

-- Orders Table
CREATE TABLE orders (
    row_id        INT PRIMARY KEY,
    order_id      VARCHAR(20) NOT NULL,
    order_date    DATE NOT NULL,
    ship_date     DATE NOT NULL,
    ship_mode     VARCHAR(20) NOT NULL,
    customer_id   VARCHAR(20) NOT NULL,
    product_id    VARCHAR(20) NOT NULL,
    city          VARCHAR(50) NOT NULL,
    state         VARCHAR(50) NOT NULL,
    postal_code   VARCHAR(10) NOT NULL,
    region        VARCHAR(20) NOT NULL,
    sales_rep     VARCHAR(100) NOT NULL,
    returned      VARCHAR(5)  NOT NULL,
    sales         DECIMAL(10,4) NOT NULL,
    quantity      INT NOT NULL,
    discount      DECIMAL(4,2) NOT NULL,
    profit        DECIMAL(10,4) NOT NULL,
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_orders_product
        FOREIGN KEY (product_id) REFERENCES products(product_id)
);
INSERT INTO orders (row_id, order_id, order_date, ship_date, ship_mode,
                     customer_id, product_id, city, state, postal_code, region,
                     sales_rep, returned, sales, quantity, discount, profit)
SELECT row_id, order_id, order_date, ship_date, ship_mode,
       customer_id, product_id, city, state, 
       LPAD(postal_code, 5, '0'),  -- fixes the leading-zero truncation issue
       region, sales_rep, returned, sales, quantity, discount, profit
FROM supply_chain;

-- EDA(Exploratory Data Analysis)
SELECT * FROM supply_chain;
/* This section looks at the sales representatives performance by number of sales, profit they brought in, profit margins,
and average discount
*/
SELECT sales_rep, SUM(sales) AS total_sales, SUM(profit) AS total_profit, 
SUM(profit)/SUM(sales)*100 AS profit_margin_pct, AVG(discount) AS avg_discount
FROM supply_chain
GROUP BY sales_rep;
SELECT YEAR(order_date) AS `year`, sales_rep, SUM(sales) AS total_sales, SUM(profit) AS total_profit, 
SUM(profit)/SUM(sales)*100 AS profit_margin_pct, AVG(discount) AS avg_discount
FROM supply_chain
GROUP BY sales_rep, YEAR(order_date)
ORDER BY `year`, sales_rep;

/* This next section aims to explore sales, profit and profit margin performance highlighting top 5 regions and cities, while also
comparing their performance per year
*/
SELECT state, SUM(sales) AS total_sales -- top 5 states by total sales
FROM supply_chain
GROUP BY state
ORDER BY total_sales DESC
LIMIT 5;

SELECT state, SUM(profit) AS total_profit -- top 5 states by total profits
FROM supply_chain
GROUP BY state
ORDER BY total_profit DESC
LIMIT 5;

SELECT city, state, SUM(sales) AS total_sales -- top 5 cities by total sales
FROM supply_chain
GROUP BY city, state
ORDER BY total_sales DESC
LIMIT 5;

SELECT city, state, SUM(profit) AS total_profit -- top 5 cities by total profits
FROM supply_chain
GROUP BY city, state
ORDER BY total_profit DESC
LIMIT 5;

-- Top 5 states in total sales per year
SELECT year, state, total_sales, sales_rank
FROM (
		SELECT 
				YEAR(order_date) AS year,
				state,
				SUM(sales) AS total_sales,
				RANK() OVER (PARTITION BY YEAR(order_date) ORDER BY SUM(sales) DESC) AS sales_rank
			FROM supply_chain
			GROUP BY state, YEAR(order_date)
            ) ranked
WHERE sales_rank <= 5
ORDER BY year, sales_rank;

-- Top 5 states in total profits per year
SELECT year, state, total_profit, profit_rank
FROM (
		SELECT 
				YEAR(order_date) AS year,
				state,
				SUM(profit) AS total_profit,
				RANK() OVER (PARTITION BY YEAR(order_date) ORDER BY SUM(profit) DESC) AS profit_rank
			FROM supply_chain
			GROUP BY state, YEAR(order_date)
            ) ranked
WHERE profit_rank <= 5
ORDER BY year, profit_rank;

-- top 5 cities per year
SELECT year, city, state, total_sales, sales_rank
FROM (
    SELECT 
        YEAR(order_date) AS year, city, state, SUM(sales) AS total_sales,
        RANK() OVER (PARTITION BY YEAR(order_date) ORDER BY SUM(sales) DESC) AS sales_rank
    FROM supply_chain
    GROUP BY YEAR(order_date), city, state
) ranked
WHERE sales_rank <= 5
ORDER BY year, sales_rank;

-- top 5 cities in profits per year
SELECT year, city, state, total_profit, profit_rank
FROM (
    SELECT 
        YEAR(order_date) AS year, city, state, SUM(profit) AS total_profit,
        RANK() OVER (PARTITION BY YEAR(order_date) ORDER BY SUM(profit) DESC) AS profit_rank
    FROM supply_chain
    GROUP BY YEAR(order_date), city, state
) ranked
WHERE profit_rank <= 5
ORDER BY year, profit_rank;

-- Sales performance by year
SELECT YEAR(order_date) AS `year`, SUM(sales) AS Total_Sales
FROM supply_chain
GROUP BY `year`
ORDER BY `year`;

-- Yearly profits vs profit margin 
SELECT YEAR(order_date) AS `year`, SUM(profit) AS total_profit, SUM(profit) / SUM(sales) * 100 AS profit_margin_pct
FROM supply_chain
GROUP BY `year`
ORDER BY `year`;

-- Yearly sales, profit, profir margin and average disocunt performance
SELECT YEAR(order_date) AS year,
       SUM(sales) AS total_sales,
       SUM(profit) AS total_profit,
       SUM(profit)/SUM(sales)*100 AS profit_margin_pct,
       AVG(discount)*100 AS avg_discount_pct
FROM supply_chain
GROUP BY year
ORDER BY year;

-- Sales and profit by category
SELECT category, SUM(sales), SUM(profit), SUM(profit)/SUM(sales)*100 AS profit_margin_pct
FROM supply_chain
GROUP BY category;
 -- sales and profits by region
SELECT region, SUM(sales), SUM(profit)
FROM supply_chain
GROUP BY region;

-- Yearly regional performance
SELECT YEAR(order_date) AS `year`, region, SUM(sales) AS total_sales, SUM(profit) AS total_profit,
SUM(profit)/SUM(sales)*100 AS profit_margin_pct
FROM supply_chain
GROUP BY `year`, region
ORDER BY region, `year` ASC;

/* Next sectioon is all about KPI calculations*/
-- 1. Average Order Value overall
SELECT AVG(order_total) AS avg_order_value
FROM (
    SELECT order_id, SUM(sales) AS order_total
    FROM supply_chain
    GROUP BY order_id
) order_totals;

-- 2.  AOV per year
SELECT YEAR(order_date) AS year, AVG(order_total) AS avg_order_value
FROM (
    SELECT order_id, MIN(order_date) AS order_date, SUM(sales) AS order_total
    FROM supply_chain
    GROUP BY order_id
) order_totals
GROUP BY YEAR(order_date)
ORDER BY year;

-- AOV per quarter 
SELECT 
    YEAR(order_date) AS year,
    QUARTER(order_date) AS quarter,
    AVG(order_total) AS avg_order_value
FROM (
    SELECT order_id, MIN(order_date) AS order_date, SUM(sales) AS order_total
    FROM supply_chain
    GROUP BY order_id
) order_totals
GROUP BY YEAR(order_date), QUARTER(order_date)
ORDER BY year, quarter;

-- This next section seeks to performa RFM analysis
-- 1. Calculating the recency, frequency and monetary values per customer
SELECT 
    customer_id,
    customer_name,
    DATEDIFF((SELECT MAX(order_date) FROM supply_chain), MAX(order_date)) AS recency_days,
    COUNT(DISTINCT order_id) AS frequency,
    SUM(sales) AS monetary
FROM supply_chain
GROUP BY customer_id, customer_name;

-- 2. Creating a view that holds the RFM scores
CREATE VIEW customer_rfm AS
SELECT 
    customer_id,
    customer_name,
    recency_days,
    frequency,
    monetary,
    NTILE(4) OVER (ORDER BY recency_days ASC) AS r_score,
    NTILE(4) OVER (ORDER BY frequency DESC) AS f_score,
    NTILE(4) OVER (ORDER BY monetary DESC) AS m_score
FROM (
    SELECT 
        customer_id,
        customer_name,
        DATEDIFF((SELECT MAX(order_date) FROM supply_chain), MAX(order_date)) AS recency_days,
        COUNT(DISTINCT order_id) AS frequency,
        SUM(sales) AS monetary
    FROM supply_chain
    GROUP BY customer_id, customer_name
) rfm_base;
SELECT * FROM customer_rfm;

SELECT *,
    CASE 
        WHEN r_score = 1 AND f_score = 1 AND m_score = 1 THEN 'Champions'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Loyal Customers'
        WHEN r_score = 1 AND f_score >= 3 THEN 'New Customers'
        WHEN r_score >= 3 AND f_score <= 2 THEN 'At Risk'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Lost/Dormant'
        ELSE 'Needs Attention'
    END AS rfm_segment
FROM customer_rfm
ORDER BY r_score, f_score, m_score;