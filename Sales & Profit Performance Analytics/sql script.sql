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

-- Analysis
-- summary statistics
SELECT COUNT(*) AS `Line Items`, COUNT(DISTINCT order_id) AS `Total Orders`, SUM(sales) AS Revenue, SUM(profit) AS `Gross Profit`, 
SUM(profit)/SUM(sales)*100 AS `Gross Margin(%)`, AVG(discount) AS `Average Discount`
FROM supply_chain;
/* Looking at the results, the company generated high volume sales of $2.3M but gross profits remained relatively low with
only $284K (gross margin of 12.45%). Discount rates average to 15.6% (16%), already signaling a wavering financial health.
I will go through a series of steps to find the root cause of this margin decay	
*/
-- 1. Investigating discounts
WITH discount_band_cte AS (
	SELECT *,
    CASE 
        WHEN discount = 0 THEN '0%'
        WHEN discount <= 0.1 THEN '1-10%'
        WHEN discount <= 0.2 THEN '11-20%'
        WHEN discount <= 0.3 THEN '21-30%'
        WHEN discount <= 0.4 THEN '31-40%'
        WHEN discount <= 0.5 THEN '41-50%'
        ELSE '50%+'
    END AS discount_band
	FROM supply_chain
)SELECT 
    discount_band, 
    COUNT(DISTINCT order_id) AS loss_making_orders,
    SUM(sales) AS revenue_lost_on,
    SUM(profit) AS total_leakage -- This will output the negative cash bleed
FROM discount_band_cte 
WHERE profit < 0 
  AND discount <= 0.20 -- Explicitly isolating "safe" discount tiers
GROUP BY discount_band
ORDER BY MAX(discount);
/*By banding the discount into 7 tiers, it is clear to see where to place a threshhold at discounts(notably 20%).
The analysis shows that every discount after 20% only generates losses,with the worse one being tier 50%+ with -$76,559,
which is more than tier 21-50% combined(-$10,357 - $25,448 - $22,999 = -$58,804).
This calls for investigation to find out which dimensions contributed to the margin decay.
*/

/* While we have the total profit accounted for, scanning the dataset shows that there are orders that brought in profits
and those that did not(orders with negative zero profits). We have a total of over $156,000 in losses(18.7% unprofitable margin)
*/


SELECT COUNT(*), COUNT(DISTINCT order_id) FROM supply_chain;

SELECT * FROM supply_chain;
/* This section looks at the sales representatives performance by number of sales, profit they brought in, profit margins,
and average discount
*/
SELECT sales_rep, SUM(sales) AS total_sales, SUM(profit) AS total_profit, 
SUM(profit)/SUM(sales)*100 AS profit_margin_pct, AVG(discount) AS avg_discount
FROM supply_chain
GROUP BY sales_rep;

/* Looking at yearly performance of our sales reps, Anna Andreadi and Chuck Magee are consistently strong across all four years. 
Kelly Wiliams, however, is a red flag, particularly in the 2014 numbers where $103,838 are in sales but only $540 in profit leading
to a 0.52% margin. The same year Kelly also drove a 26% average discount in sales, which may have led to the profit decline. 
This accurately highlights high sales low profits due to these kinds of discounting.
*/
SELECT YEAR(order_date) AS `year`, sales_rep, SUM(sales) AS total_sales, SUM(profit) AS total_profit, 
SUM(profit)/SUM(sales)*100 AS profit_margin_pct, AVG(discount) AS avg_discount
FROM supply_chain
GROUP BY sales_rep, YEAR(order_date)
ORDER BY `year`, sales_rep;

-- Sales and profit by category
SELECT category, SUM(sales) AS Total_Sales, SUM(profit) AS Total_profits, SUM(profit)/SUM(sales)*100 AS profit_margin_pct
FROM supply_chain
GROUP BY category;

/* Based on previous analysis, furniture appears to be dramatically underperforming despite huge sales, with only a 2.5% 
profit margin. Digging deeper, this flaw is caused by the tables sub category that huge sales but very low profit
causing a staggering -8.6% profit margin, followed by bookcases with a -3% profit margin. It is clear that tables and bookcases are 
costing the company money.
*/
SELECT sub_category, SUM(sales), SUM(profit), SUM(profit)/SUM(sales)*100 AS profit_margin_pct
FROM supply_chain
WHERE category = 'Furniture'
GROUP BY sub_category;

/*technology category is leading with a 17.4% profit margin, with the copiers sub category hiking this margin with a stunning 37.2%
followed by accessories with 25.1%. What follows after technology is office supplies category that has some incredible margin performances from:
envelopes with 42.3%, paper with 43.4% and lables with 44.4%. The only thing costing this category money is the supplies sub category
with a -2.5% margin
*/
SELECT category, sub_category, SUM(sales), SUM(profit), SUM(profit)/SUM(sales)*100 AS profit_margin_pct
FROM supply_chain
WHERE category IN('Technology', 'Office Supplies')
GROUP BY category, sub_category
ORDER BY category;


/* This next section aims to explore sales, profit and profit margin performance highlighting top 5 regions and cities, while also
comparing their performance per year
*/
/* Top 5 states by total sales vs their total profits
California and New York are doing incredibly well in both sales and profits. One issue noted, however, is that Texas looks good in sales 
view(ranks top 3) but is instead showing big losses(-$25729.29) presumably because of the 37% average discount on items. The same goes for
Pennsylvania which shows $15560 in losses(32% average discount)
*/
SELECT state, SUM(sales) AS total_sales, SUM(profit) AS total_profit, AVG(discount)  
FROM supply_chain
GROUP BY state
ORDER BY total_sales DESC
LIMIT 5;
-- a deepdive on Texas state to view cities with lossess and their discounts(they range from 20% to 80%). 
SELECT city, SUM(profit) AS total_profit, AVG(discount)
FROM supply_chain
WHERE state = 'Texas'
GROUP BY city;

-- top 5 states by total profits
SELECT state, SUM(profit) AS total_profit, SUM(sales) AS total_sales 
FROM supply_chain
GROUP BY state
ORDER BY total_profit DESC
LIMIT 5;
-- top 5 cities by total sales
SELECT city, state, SUM(sales) AS total_sales, SUM(profit) AS total_profit 
FROM supply_chain
GROUP BY city, state
ORDER BY total_sales DESC
LIMIT 5;
-- top 5 cities by total profits
SELECT city, state, SUM(profit) AS total_profit, SUM(sales) AS total_sales 
FROM supply_chain
GROUP BY city, state
ORDER BY total_profit DESC
LIMIT 5;

-- Top 5 states in total sales per year
SELECT year, state, total_sales, total_profits, sales_rank
FROM (
		SELECT 
				YEAR(order_date) AS year, state, SUM(sales) AS total_sales, SUM(profit) AS total_profits,
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
SELECT year, city, state, total_profits, city_rank
FROM (
    SELECT 
        YEAR(order_date) AS year, city, state, SUM(profit) AS total_profits,
        RANK() OVER (PARTITION BY YEAR(order_date) ORDER BY SUM(profit) DESC) AS city_rank
    FROM supply_chain
    GROUP BY YEAR(order_date), city, state
) ranked
WHERE city_rank <= 5
ORDER BY year, city_rank;

-- Sales performance by year
SELECT YEAR(order_date) AS `year`, SUM(sales) AS Total_Sales, SUM(profit) AS Total_profits, SUM(profit) / SUM(sales) * 100 AS profit_margin_pct,
AVG(discount)*100 AS avg_discount_pct
FROM supply_chain
GROUP BY `year`
ORDER BY `year`;

 -- sales and profits by region
SELECT region, SUM(sales), SUM(profit)
FROM supply_chain
GROUP BY region;

-- Yearly regional performance: 
SELECT YEAR(order_date) AS `year`, region, SUM(sales) AS total_sales, SUM(profit) AS total_profit,
SUM(profit)/SUM(sales)*100 AS profit_margin_pct, AVG(discount)*100 AS avg_discount_pct
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
/* The AOV shows a trendy decline each year despite growth of sales. This may mean that growth is coming from many orders 
and not bigger orders.
*/
SELECT YEAR(order_date) AS year, AVG(order_total) AS avg_order_value
FROM (
    SELECT order_id, MIN(order_date) AS order_date, SUM(sales) AS order_total
    FROM supply_chain
    GROUP BY order_id
) order_totals
GROUP BY YEAR(order_date)
ORDER BY year;

SELECT year(order_date), AVG(sales) AS AOV FROM supply_chain GROUP BY year(order_date);

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

CREATE VIEW rfm_segment AS
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

-- Number of customers per rfm segment: The highest number, 261 belong to the 'Lost/dormant' segment, while the 'Champions' are 35.
SELECT rfm_segment, COUNT(*) AS customer_count,  SUM(monetary) AS total_revenue
FROM rfm_segment
GROUP BY rfm_segment
ORDER BY customer_count DESC;
