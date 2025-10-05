/* Several things to deal with in this dataset.
1. Limit the ages to be between 18 and 70
2.Convert loan_amnt column from a string to a integer datatype
3. Change historical_default values into understandable values(No/Yes)
4. loan_intent column(HOMEIMPROVEMENT and DEBTCONSOLIDATION)
5. Add column(age_bracket) for ease in visualization
6. Handling null/blank values
*/
SELECT *
FROM loans;

-- 1.
CREATE TABLE clean_loans AS
SELECT *
FROM loans
WHERE customer_age BETWEEN 18 AND 71;

-- 2. Convert loan_amnt column from a string to a integer datatype
SELECT *
FROM clean_loans;

UPDATE clean_loans
SET loan_amnt =SUBSTR(SUBSTRING_INDEX(loan_amnt, ".", 1), 3); -- 1st process extracting string to eliminate special characters and decimal values

UPDATE clean_loans
SET loan_amnt = REPLACE(loan_amnt, ',', ''); -- 2nd process removing commas

ALTER TABLE clean_loans
MODIFY COLUMN loan_amnt INT; -- Final process data type conversion

-- 3. Change historical_default values into understandable values(No/Yes)
UPDATE clean_loans
SET historical_default = CASE
	WHEN historical_default = 'N' THEN 'No'
    WHEN historical_default = 'Y'THEN 'Yes'
    ELSE historical_default
END;

-- 4. loan_intent column(HOMEIMPROVEMENT and DEBTCONSOLIDATION)
UPDATE clean_loans
SET loan_intent = CASE
	WHEN loan_intent = 'DEBTCONSOLIDATION' THEN 'DEBT CONSOLIDATION'
    WHEN loan_intent = 'HOMEIMPROVEMENT' THEN 'HOME IMPROVEMENT'
    ELSE loan_intent
END;    

-- 5. Add column(age_bracket) for ease in visualization
ALTER TABLE clean_loans
ADD COLUMN age_bracket VARCHAR(25);
 
UPDATE clean_loans
SET age_bracket = CASE
	WHEN customer_age BETWEEN 18 AND 25 THEN 'Youth'
    WHEN customer_age BETWEEN 25 AND 35 THEN 'Young Adults'
    WHEN customer_age BETWEEN 35 AND 45 THEN 'Early Middle age'
    WHEN customer_age BETWEEN 45 AND 65 THEN 'Middle age'
    ELSE 'Elderly'
END;    

-- 6. Handling null/blank values
ALTER TABLE clean_loans
drop column historical_default; -- contains a big % of null values making it unreliable

SELECT *
FROM clean_loans;

SELECT loan_amnt
FROM clean_loans
WHERE loan_amnt IN(' ');