/* This script comprises of the data cleaning, preprocessing and integratino
   of a marketing campaign dataset. It consists of customer details, product preferences and spend per 
   customer, campaign acceptance status in binary values(0,1) and channels used during
   purchases.*/
   

ALTER TABLE marketing
RENAME COLUMN `ï»¿annual_income(USD)` TO `annual_income(USD)`;

-- I saw no need for thes columns so I droppd them They are, however, available in the original dataset
ALTER TABLE marketing
DROP COLUMN Z_CostContact;

ALTER TABLE marketing
DROP COLUMN Z_Revenue;

ALTER TABLE marketing
DROP COLUMN MntRegularProds;

-- I added a customer ID column as I saw it would be helpful during visualizations in power bi r/ships
ALTER TABLE marketing
ADD COLUMN customer_ID INT AUTO_INCREMENT PRIMARY KEY FIRST;

-- I then began splitting the main dataset into 4 tables: customers, products, campaigns and channels
CREATE TABLE customers AS
SELECT customer_ID, Age, `annual_income(USD)`, education_Basic,`education_2n Cycle`, education_Graduation,
		education_Master, education_PhD, marital_Single, marital_Married, marital_Together,
        marital_Divorced, marital_Widow, Kids_per_home, Teens_per_home, Customer_Days
FROM marketing;

CREATE TABLE campaigns AS
SELECT customer_ID, Campaign1, Campaign2, Campaign3, Campaign4, Campaign5, Response, Complain,
		AcceptedCmpOverall
FROM marketing;

ALTER TABLE customers  -- converting the column customer days into months/years for ease in line graphs
ADD COLUMN customer_months INT;
UPDATE customers
SET customer_months = FLOOR(Customer_Days / 30);

ALTER TABLE customers
ADD COLUMN customer_years INT;
UPDATE customers
SET customer_years = FLOOR(Customer_Days / 365.25);

ALTER TABLE products
ADD COLUMN true_total_spend INT;

UPDATE products
SET true_total_spend = `Wine(USD)` + `Fruits(USD)` + `Meat_prods(USD)` + `Fish_prods(USD)` + `Sweet_prods(USD)` + `Gold_prods(USD)`;

CREATE TABLE products AS
SELECT customer_ID, `Wine(USD)`, `Fruits(USD)`, `Meat_prods(USD)`, `Fish_prods(USD)`, `Sweet_prods(USD)`, `Gold_prods(USD)`,
		MntTotal
FROM marketing;

-- segmenting cutomer income into ncome brackets
ALTER TABLE customers
ADD COLUMN Income_bracket VARCHAR(50);

UPDATE customers
SET Income_bracket = 
CASE WHEN `annual_income(USD)` < 10000 THEN 'Very Low Income'
	 WHEN `annual_income(USD)` BETWEEN 10000 AND 30000 THEN 'Low Income'
	 WHEN `annual_income(USD)` BETWEEN 30000 AND 60000 THEN 'Middle Income'
	 WHEN `annual_income(USD)` BETWEEN 60001 AND 90000 THEN 'Upper Middle'
	 ELSE 'High Income'
     END;

CREATE TABLE channels AS
SELECT customer_ID, Web_purchase, Catalogue_purchase, Store_purchase, Discount_purchase,  Recency, NumWebVisitsMonth
FROM marketing;

-- Customers Table
SELECT *
FROM customers;

-- 1. Proper education classification instead of just binary values*
ALTER TABLE customers
ADD COLUMN Education VARCHAR(50);

UPDATE customers
SET Education = 
CASE WHEN education_Basic = 1 THEN "Basic"
	WHEN `education_2n Cycle` = 1 THEN "2n_Cycle"
    WHEN education_Graduation = 1 THEN "Graduation"
    WHEN education_Master = 1 THEN "Masters"
    WHEN education_PhD = 1 THEN "PhD"
    END;

-- 2. same with Marital Status    
ALTER TABLE customers
ADD COLUMN Marital_Status VARCHAR(50);

UPDATE customers
SET Marital_Status =
CASE WHEN marital_Single THEN "Single"
	 WHEN marital_Married THEN "Married"
     WHEN marital_Together THEN "Together"
     WHEN marital_Divorced THEN "Divorced"
     WHEN marital_Widow THEN "Widow"
     END;

-- 3. classifying Age groups to understand patterns easier
ALTER TABLE customers
ADD COLUMN Age_group VARCHAR(50);

UPDATE customers
SET Age_group =
CASE WHEN Age < 25 THEN "Below 25"
	 WHEN Age BETWEEN 25 AND 35 THEN "25-34"
	 WHEN Age BETWEEN 35 AND 45 THEN "35-44"
     WHEN Age BETWEEN 45 AND 55 THEN "45-54"
     WHEN Age BETWEEN 55 AND 65 THEN "55-65"
     WHEN Age > 65 THEN "65+"
     END;

-- Channels
SELECT *
FROM channels;

ALTER TABLE channels
ADD COLUMN Frequency INT;

UPDATE channels
Set Frequency = Web_purchase + Catalogue_purchase + Store_purchase + Discount_purchase;

-- RFM ANALYSIS
CREATE TABLE RFM_summary AS
SELECT c.customer_ID, c.Recency AS Recency, c.Frequency AS Frequency, p.true_total_spend AS monetary 
FROM products p
JOIN channels c
ON p.customer_ID = c.customer_ID;