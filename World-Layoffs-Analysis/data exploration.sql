/*
We will be performing exploratory analysis on our previously cleaned layoffs dataset
in order to answer interesting questions:
*/
SELECT *
FROM layoffs_dup2;

-- 1. highest number of employees laid off in total and percentage
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_dup2;

-- 2. companies that laid off all their employees
SELECT *
FROM layoffs_dup2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- 3. total no. of employees laid off per company 
SELECT company, SUM(total_laid_off)
FROM layoffs_dup2
GROUP BY company
ORDER BY 2 DESC;

-- 4. total no. of employees laid off per industry 
SELECT industry, SUM(total_laid_off)
FROM layoffs_dup2
GROUP BY industry
ORDER BY 2 DESC;

-- 5. total no. of employees laid off per country
SELECT country, SUM(total_laid_off)
FROM layoffs_dup2
GROUP BY country
ORDER BY 2 DESC;

-- 6. span of how long
SELECT MAX(`date`), MIN(`date`)
FROM layoffs_dup2;

-- 7. total no. of employees laid off per year
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_dup2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

SELECT stage, SUM(total_laid_off)
FROM layoffs_dup2
GROUP BY stage
ORDER BY 2 DESC;

 -- 8. total number of companies per industry per country
SELECT COUNT(industry),industry,country
FROM layoffs_dup2
GROUP BY industry,country;

-- 9. calculating a cumulative total
SELECT SUBSTRING(`date`,1,7) `month`, SUM(total_laid_off)
FROM layoffs_dup2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `month`
ORDER BY 1 DESC;

WITH rolling_total AS(
	SELECT SUBSTRING(`date`,1,7) `month`, SUM(total_laid_off) AS month_total
	FROM layoffs_dup2
	WHERE SUBSTRING(`date`,1,7) IS NOT NULL
	GROUP BY `month`
	ORDER BY 1 DESC
)
SELECT `month`, month_total, SUM(month_total)
OVER(ORDER BY `month`) AS rolling_total
FROM rolling_total;

-- 10. Top 5 companies with highest number of layoffs per year
WITH company_year(Company, Total, `Year`) AS
(
SELECT company, SUM(total_laid_off), YEAR(`date`)
FROM layoffs_dup2
GROUP BY company, YEAR(`date`)
), company_rank AS (
SELECT *, DENSE_RANK() OVER(PARTITION BY `Year` ORDER BY Total DESC ) AS Ranking
FROM company_year
WHERE `Year` IS NOT NULL
)
 SELECT *
 FROM company_rank
 WHERE Ranking <= 5
 ;
 -- 11. average perecentage of layoffs per stage
SELECT stage, ROUND(AVG(percentage_laid_off),2) AS average_percentage_stage
FROM layoffs_dup2
GROUP BY stage
ORDER BY 2 DESC;










