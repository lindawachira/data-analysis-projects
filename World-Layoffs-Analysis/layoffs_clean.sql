/*
This file shows the entire process taken to clean
this dataset using mysql, from dealing with duplicate values
to fixing blank and null values
*/

SELECT *
FROM layoffs;

-- duplicate raw dataset
CREATE TABLE layoffs_dup
LIKE layoffs;
SELECT *
FROM layoffs_dup;

-- insert values into new table
INSERT INTO layoffs_dup
SELECT *
FROM layoffs;

-- 1. Remove duplicate values
SELECT *,
ROW_NUMBER() -- producing row numbers 
OVER(PARTITION BY  location,industry, total_laid_off, percentage_laid_off, `date`,stage, country, funds_raised_millions) AS row_num
FROM layoffs_dup;

-- recreate as cte for easier querying
WITH duplicate_rows AS (
SELECT *,
ROW_NUMBER()
OVER(PARTITION BY  location,industry, total_laid_off, percentage_laid_off, `date`,stage, country, funds_raised_millions) AS row_num
FROM layoffs_dup
)
SELECT *
FROM duplicate_rows;

-- creating another table for removal of rows > 1
CREATE TABLE `layoffs_dup2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_dup2;

INSERT INTO layoffs_dup2
SELECT *,
ROW_NUMBER()
OVER(PARTITION BY  location,industry, total_laid_off, percentage_laid_off, `date`,stage, country, funds_raised_millions) AS row_num
FROM layoffs_dup;

-- removing duplicate values
DELETE
FROM layoffs_dup2
WHERE row_num > 1;


-- 2. Standardize the data
-- fixing company column
SELECT *
FROM layoffs_dup2;

SELECT company, TRIM(company) 
FROM layoffs_dup2;

UPDATE layoffs_dup2  
SET company = TRIM(company);

-- fixing country column
SELECT *
FROM layoffs_dup2;

SELECT DISTINCT country,TRIM(TRAILING '.' FROM country)
FROM layoffs_dup2;

UPDATE layoffs_dup2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE "United States%";

-- fixing industry column
SELECT *
FROM layoffs_dup2;

SELECT DISTINCT industry
FROM layoffs_dup2;

UPDATE layoffs_dup2
SET industry = "Crypto"
WHERE industry LIKE "Crypto%";

-- fixing date column
SELECT *
FROM layoffs_dup2;

ALTER TABLE layoffs_dup2
MODIFY COLUMN `date` DATE;

SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_dup2;

UPDATE layoffs_dup2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');


-- 3. Sort out null/blank values
SELECT *
FROM layoffs_dup2
WHERE industry IS NULL OR industry = '';

-- a self join to check whether the null and blank values of industry based on company can be filled
SELECT t1.industry, t2.industry
FROM layoffs_dup2 t1
JOIN layoffs_dup2 t2
ON t1.company = t2.company
AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
 AND t2.industry IS NOT NULL;
 
 -- converting blanks in industry to nulls
 UPDATE layoffs_dup2
 SET industry = NULL
 WHERE industry = '';
 
UPDATE layoffs_dup2 t1
	JOIN layoffs_dup2 t2
	ON t1.company = t2.company
	AND t1.location = t2.location
SET t1.industry = t2.industry
	WHERE t1.industry IS NULL
	AND t2.industry IS NOT NULL;
-- cross checking to see if it worked
SELECT industry
FROM layoffs_dup2
WHERE company = "Airbnb";

-- taking a look at total and percentage laid off
SELECT *
FROM layoffs_dup2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- based off of these columns they probably may not have laid off people hence null
DELETE
FROM layoffs_dup2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_dup2;
-- We no longer need the row_num column as it was just an identifer for duplicate values
ALTER TABLE layoffs_dup2
DROP COLUMN row_num;

 
 
 
 
 
 
 






