-- Opening database
USE economy_trends;
/*
 We will be using two datasets:global_economic_data and
 continent_regions. The latter will be used to map countries
 for effective analysis and visualization
 */
SELECT *
FROM global_economic_data;
 -- A little bit of cleaning,converting data types for these two columns
ALTER TABLE global_economic_data
MODIFY COLUMN `Value` DECIMAL(15,2),   -- from TEXT
MODIFY COLUMN `Year` YEAR; -- from INT

SELECT *
FROM continents_regions;
-- Creating a separate tables from parent table global_economic_data
-- 1.For total global gdp stats
CREATE TABLE global_gdp_stats AS
SELECT *
FROM global_economic_data
WHERE Country = "Total, all countries or areas";

ALTER TABLE global_gdp_stats
RENAME COLUMN Country TO World;

-- 2.For total regional gdp stats
CREATE TABLE region_gdp_stats AS
SELECT *
FROM global_economic_data
WHERE Country IN ('Africa','Americas','Asia','Europe','Oceania');

ALTER TABLE region_gdp_stats
RENAME COLUMN Country TO Region;

 -- Replacing specific values in Sub-region to map over effectively
UPDATE continents_regions
SET `Intermediate-region` = 'Central America'
WHERE `Intermediate-region` = 'Latin America and the Caribbean'
  AND Country IN ('Guatemala', 'Honduras', 'Nicaragua', 'El Salvador', 'Costa Rica', 'Panama', 'Belize');


SELECT *
FROM sub_region_gdp_stats;

-- 3.For total sub-regional gdp stats
CREATE TABLE sub_region_gdp_stats AS
SELECT *
FROM global_economic_data
WHERE Country IN ('Central Asia','Eastern Asia','Eastern Europe',
					'Latin America and the Caribbean','Melanesia','Micronesia',
                    'Northern Africa','Northern America','Northern Europe',
                    'Polynesia','South-eastern Asia','Southern Asia','Southern Europe',
                    'Sub-Saharan Africa','Western Asia','Western Europe','Australia and New Zealand');
                    
ALTER TABLE sub_region_gdp_stats
RENAME COLUMN Country TO `Sub-region`;

/* I want to create a separate country table with pure countries only,derive
 from global_economic_data table. Plan is to compare the country cloumn in
 both tables and see which rows will be cleaned up(renaming/deleting)
 */
SELECT g.Country,c.Country
FROM global_economic_data G
LEFT JOIN continents_regions c
ON g.Country=c.Country
UNION
SELECT g.Country,c.Country
FROM global_economic_data G
RIGHT JOIN continents_regions c
ON g.Country=c.Country;

-- we will remove two rows
DELETE FROM global_economic_data
WHERE Country IN('Sudan [former]','Netherlands Antilles [former]');
-- renaming columns to match both global_economic_data and continents_regions
UPDATE continents_regions
SET Country=CASE
	WHEN Country = 'Korea, Republic of' THEN 'Republic of Korea'
    WHEN Country = 'Czech Republic' THEN 'Czechia'
    WHEN Country = 'Virgin Islands (British)' THEN 'British Virgin Islands'
    WHEN Country = 'Hong Kong' THEN 'China, Hong Kong SAR'
    WHEN Country = 'Macao' THEN 'China, Macao SAR'
    WHEN Country = 'Côte D''Ivoire' THEN 'Côte d’Ivoire'
    WHEN Country = 'Guinea Bissau' THEN 'Guinea-Bissau'
    WHEN Country = 'Iran' THEN 'Iran (Islamic Republic of)'
    WHEN Country = 'Laos' THEN 'Lao People''s Dem. Rep.'
    WHEN Country = 'Micronesia (Federated States of)' THEN 'Micronesia (Fed. States of)'
    WHEN Country = 'Netherlands' THEN 'Netherlands (Kingdom of the)'
    WHEN Country = 'Macedonia' THEN 'North Macedonia'
    WHEN Country = 'Moldova' THEN 'Republic of Moldova'
    WHEN Country = 'Russia' THEN 'Russian Federation'
    WHEN Country = 'Saint Vincent and the Grenadines' THEN 'Saint Vincent & Grenadines'
    WHEN Country = 'Palestine, State of' THEN 'State of Palestine'
    WHEN Country = 'Syria' THEN 'Syrian Arab Republic'
    WHEN Country = 'Turkey' THEN 'Türkiye'
    WHEN Country = 'Tanzania' THEN 'United Rep. of Tanzania'
    WHEN Country = 'United States' THEN 'United States of America'
    WHEN Country = 'Venezuela' THEN 'Venezuela (Boliv. Rep. of)'
    WHEN Country = 'Bolivia' THEN 'Bolivia (Plurin. State of)'
	WHEN Country = 'Vietnam' THEN 'Viet Nam'
	ELSE Country
    END;
-- now that we've made the updates let's create the table
-- 4. For countries_gdp_stats
CREATE TABLE Countries_gdp_stats AS
SELECT ged.Country,ged.`Year`,ged.Series,ged.`Value`
FROM global_economic_data ged
JOIN continents_regions cr
ON ged.Country=cr.Country;

SELECT *
FROM countries_gdp_stats;
