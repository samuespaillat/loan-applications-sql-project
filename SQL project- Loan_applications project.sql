-- 1. Data prep
-- 2. Remove duplicates
-- 3. Standardized data
-- 4. Deal with NULL (if possible) and Remove uneeded data


##--1. Data prep
-- Creating a copy of the raw data before proceding as a way to have a backup

SELECT * 
FROM loan_applications;

-- stg= staging, just an abbreviation

CREATE TABLE Loan_stg
LIKE loan_applications;

INSERT Loan_stg
SELECT *
FROM loan_applications;

SELECT *
FROM loan_stg;

##--1. Removing Duplicates
-- I will be adding the row_num column using the fucntion row_number and partitioning by loan_id
-- Essentially where row_num is = 2, then there is a duplicate the needs to be looked at
-- we won't be adding this new column into loan_applications, but to a copy of it instead

SELECT *,
ROW_NUMBER() OVER (Partition BY Loan_id) 'Row_num'
FROM loan_stg;

CREATE TABLE loan_stg2
LIKE loan_stg;

ALTER TABLE loan_stg2
ADD COLUMN row_num INT;

INSERT INTO loan_stg2
SELECT *, ROW_NUMBER() OVER (Partition BY Loan_id) AS Row_num
FROM loan_stg;

-- Creating another copy of loan_stg, but this time 
-- the comlumn row_num is a part of it rather than being a cte

TRUNCATE loan_stg2;
-- Used truncate to fix issue when inserting loan_stg into loan_stg2, (code 1136)
-- This basically cleaned out the values in the table, allowing me to insert those newer values again
-- After truncate re-run INSERT statement again with the correct number of columns

SELECT *
FROM loan_stg2
WHERE row_num>1;

-- This shows possible duplicates
-- If row _num is > 1, than it is a dublicate.

DELETE 
FROM loan_stg2
WHERE row_num >1;

SELECT *
FROM loan_stg2;

-- Table should have no duplicates now

##--2. Standardizing 
-- The goal here is to ensure data is formatted correctly and consistently
-- At the end we can then change the datatypes for the columns the need it,
-- to allow us to run aggregate functions and properly import the data

-- First we are dealing with the loan purpose column

SELECT UPPER(LEFT(TRIM(REPLACE(loan_purpose, '_', ' ')),1))
FROM loan_stg2;

-- This query TRIMs extra spaces in the beginning then REPLACES '_' with ' ' and 
-- then selects the value in position 1 of the left side and turns it to uppercase
-- Basically just selects the first letter (position 1) and turns the single letter into uppercase


SELECT LOWER(SUBSTRING(TRIM(REPLACE(loan_purpose, '_', ' ')), 2))
FROM loan_stg2;

-- This query TRIMs extra spaces in the beginning then REPLACES '_' with ' ' and 
-- then selects the values from position 2 and forward and turns them into lowercase
-- Basically just selects everything from the second letter and forward (position 2) and turns it into a lowercase

SELECT CONCAT(UPPER(LEFT(TRIM(REPLACE(loan_purpose, '_', ' ')),1)), LOWER(SUBSTRING(TRIM(REPLACE(loan_purpose, '_', ' ')), 2)))
FROM loan_stg2;

-- The concact statement combines the queries above
-- so 'E' from UPPER query gets combined with 'ducation' from the lower query
-- together it returns the 'Education' as a field in the column

-- This is something the will happen a lot throughout the project where
-- I will first run a select statement to check if the table updated correctly and then UPDATE

UPDATE loan_stg2
SET loan_purpose = CONCAT
(UPPER(LEFT(TRIM(REPLACE(loan_purpose, '_', ' ')),1)), 
LOWER(SUBSTRING(TRIM(REPLACE(loan_purpose, '_', ' ')), 2)))
;
-- Now the actual column is updated and all fields have a consistent format
-- The CONCAT just allows us to combine both queries from above

-- Now for the customer_name column:

SELECT TRIM(customer_name)
FROM loan_stg2;

SELECT *
FROM loan_stg2;

SELECT CONCAT
(UPPER(LEFT(TRIM(REPLACE(customer_name,'_', ' ')), 1)), 
LOWER(SUBSTRING(TRIM(REPLACE(customer_name, '_',' ')), 2)))
FROM loan_stg2;

-- While this could work, it isn't best practice
-- Ideally names are in proper case:

UPDATE loan_stg2
SET customer_name= TRIM(customer_name);
-- This could have been done earlier and would probably make queries easier to read and write


SELECT UPPER(LEFT(SUBSTRING_INDEX(customer_name, ' ',1), 1))
FROM loan_stg2;

SELECT LOWER(SUBSTRING(SUBSTRING_INDEX(customer_name, ' ',1), 2))
FROM loan_stg2;

-- SUBSTRING cuts by position: “start at character 2 and return the rest.” It counts characters.
-- SUBSTRING_INDEX cuts by delimiter: “return everything before the 1st space.” 
-- It looks for a separator character (delimiter) like a space, comma, or dash.

-- SUBSTRING_INDEX (column_name, '[delimiter]', 1 (first word), or (-1 (last word)
-- SUBSTRING_INDEX2 cuts from the second delimiter instead of one. 

-- if -1 keeps everything after the last space -2 keeps everything after the second to last space
-- 1 keeps everything before the first space 2 keeps everything from the first two spaces
-- useful for cases with names like 'Marry jane Watson' 


SELECT CONCAT(UPPER(LEFT(SUBSTRING_INDEX(customer_name, ' ',1), 1)),LOWER(SUBSTRING(SUBSTRING_INDEX(customer_name, ' ',1), 2)))
FROM loan_stg2;
-- This was just for the first name or first part or the text.
-- same logic as above, grab the first letter in position 1, make it uppercase
-- Then grab the rest of the text from position 2 and forward and make it lowercase
-- Here comes the last name part:

SELECT SUBSTRING_INDEX(customer_name, ' ', -1)
FROM loan_stg2;

-- This just returns the last names

SELECT CONCAT(UPPER(LEFT(SUBSTRING_INDEX(customer_name, ' ', -1), 1)), LOWER(SUBSTRING((SUBSTRING_INDEX(customer_name, ' ', -1)), 2)))
FROM loan_stg2;

-- To put everything together:

SELECT 
CONCAT(UPPER(LEFT(SUBSTRING_INDEX(customer_name, ' ',1), 1)), 
	LOWER(SUBSTRING(SUBSTRING_INDEX(customer_name, ' ',1), 2)),
' ',
	UPPER(LEFT(SUBSTRING_INDEX(customer_name, ' ', -1), 1)), 
	LOWER(SUBSTRING((SUBSTRING_INDEX(customer_name, ' ', -1)), 2)))
FROM loan_stg2;

UPDATE loan_stg2
SET customer_name = 
CONCAT(UPPER(LEFT(SUBSTRING_INDEX(customer_name, ' ',1), 1)), 
	LOWER(SUBSTRING(SUBSTRING_INDEX(customer_name, ' ',1), 2)),
' ',
	UPPER(LEFT(SUBSTRING_INDEX(customer_name, ' ', -1), 1)), 
	LOWER(SUBSTRING((SUBSTRING_INDEX(customer_name, ' ', -1)), 2)))
    ;
SELECT * 
FROM loan_stg2;
    
-- names are properly formatted now
-- there is also INITCAP(). PostgreSQL and Oracle have it, and it turns harry potter into Harry Potter in one step.
-- MySQL doesn’t have it, which is why we build it from UPPER, LEFT, SUBSTRING, and CONCAT.

-- Now for the states

SELECT DISTINCT state
FROM loan_stg2;
-- By using DISTINCT it allows us to see all the different state names bundle up into a list
-- We can catch data entry mistakes like Pennsyvania and turn it into PA to match the rest of the list

UPDATE loan_stg2
SET state = UPPER(TRIM(state));

-- By trimming and making all states as uppercase, it makes it easier to use case statements
-- it will also ensure all values have the same case so NY isn't ny or Ny

SELECT state,
CASE
	WHEN state = 'PENNSYLVANIA' THEN 'PA'
    WHEN state = 'CALIFORNIA' THEN 'CA'
    WHEN state = 'NEW YORK' THEN 'NY'
    WHEN state = 'NEW JERSEY' THEN 'NJ'
    WHEN state = 'FLORIDA' THEN 'FL'
    WHEN state = 'OHIO' THEN 'OH'
    WHEN state = 'TEXAS' THEN 'TX'
    ELSE state
    END AS STATE
    FROM loan_stg2;

UPDATE loan_stg2
SET state = 
CASE
	WHEN state = 'PENNSYLVANIA' THEN 'PA'
    WHEN state = 'CALIFORNIA' THEN 'CA'
    WHEN state = 'NEW YORK' THEN 'NY'
    WHEN state = 'NEW JERSEY' THEN 'NJ'
    WHEN state = 'FLORIDA' THEN 'FL'
    WHEN state = 'OHIO' THEN 'OH'
    WHEN state = 'TEXAS' THEN 'TX'
    ELSE state
END;

-- Now all 7 states have same format and only abbreviations

SELECT * 
FROM loan_stg2;

-- The column Loan_amount has the wrong datatype, should be INT instead of text
-- Since there are symbols involved, we first have to clean the data before changing
-- If we changed the datatype now with all the symbols, it could fail or mangle the results

SELECT TRIM(REPLACE(REPLACE(loan_amount,'$', ''), ',', ''))
FROM loan_stg2;

UPDATE loan_stg2
SET loan_amount = 
	TRIM(REPLACE(REPLACE(loan_amount,'$', ''), ',', ''));

-- There are also negative values which seem to be an entry error

SELECT *
FROM loan_stg2
WHERE loan_amount <0;

UPDATE loan_stg2
SET loan_amount = ABS(loan_amount)
WHERE loan_amount < 0;

-- Some of the values in this column just appear to be way to big for a loan ammount
SELECT *
FROM loan_stg2
WHERE loan_amount > 60000
ORDER BY loan_amount DESC;

-- There are 8 loan greater than $60,000 all of which are greater than or equal to $400,000
	-- The closest loan to 400,000 is around 59,500. 60,000 is just the highest number the returned
	-- these high loans
    
-- While dividing by 100 makes the numbers look much more realistic and this was probably an error
-- There is no way to know for certain whether these 8 rows have an entry error or if they are large loans

-- For now these will be turned to NULL since there is no way to know for certain without checking from another data source
	-- It's not everyday you see an car purchase loan for '400,000'

SELECT loan_purpose,(loan_amount/1)
FROM loan_stg2
WHERE loan_amount > 60000
ORDER BY loan_amount DESC;

UPDATE loan_stg2
SET loan_amount = NULL
WHERE loan_amount > 60000;

-- We can use loan_stg or Loan_applications to check the values and reference them
-- In order to update them, we can use the loan_id from those other tables 
-- and the confirmed loan values to update loan_stg2

-- Now for interest_rate, we can't have % in values, it turns columns into a text
-- the column becomes a text (which it is now technically) and you can’t average or sort it properly
-- it's best to keep numbers as whole numbers or decimals to run aggregate functions
-- and when we chage datatypes later on, it will save us a lot of headaches

UPDATE loan_stg2
SET interest_rate = TRIM(REPLACE(interest_rate, '%', ''));

-- Next we have to make all values where there isn't a loan amount a null
-- We don't want blank or N/A values 

UPDATE loan_stg2
SET loan_amount = NULL
WHERE loan_amount = '';

UPDATE loan_stg2
SET loan_amount = NULL
WHERE loan_amount= 'N/A';

-- Next we have to make all values be consistent
-- some of these values were entered as decimals and others as percentages
-- to fix this, we can multiply or divide by 100:

SELECT ROUND(interest_rate*100, 2)
FROM loan_stg2
WHERE interest_rate < 1;

-- This query turns any interest rates from a decimal to a 'percentage form' without the %
-- by multiplying by 100
-- Then we can use ROUND to make sure all values have 2 values after the decimal and round  where needed

UPDATE loan_stg2
SET interest_rate = 
	ROUND(interest_rate*100, 2)
	WHERE interest_rate < 1;

UPDATE loan_stg2
SET interest_rate = null
WHERE interest_rate = '0';
-- There was a missed step to turn blank values into NULL. 
-- This resulted in blank values being multiplied and the product was '0'
-- Since interest rates are likely going to be a number >1 
-- we can turn all '0' into NULL values

SELECT *
FROM loan_stg2;

-- Next we handle the term_months to make sure they are all in months and not years
-- By leaving only numbers it makes it much easirt to use aggreagate functions and run queries
UPDATE loan_stg2
SET term_months = NULL
WHERE term_months= '';

SELECT DISTINCT term_months
FROM loan_stg2;

SELECT DISTINCT REPLACE(term_months, 'mo', '')
FROM loan_stg2
WHERE term_months LIKE '%mo';

-- This query searches up any values the have 'months' at the end.
-- The goal is to figure out which rows have 'months' at the end and then take it out by using replace function
-- essentially gets rid of the months which will help when doing aggregates functions or when looking up a value
-- since '24 months' '2 years' and '24' are all technically saying the same, we just want it to look consistent

UPDATE loan_stg2
SET term_months =
REPLACE(term_months, 'mo', '')
WHERE term_months LIKE '%mo';

UPDATE loan_stg2
SET term_months = TRIM(REPLACE(REPLACE(term_months, 'months', ''), 'years', ''));

UPDATE loan_stg2
SET term_months = CASE
WHEN term_months = 2 THEN 24
WHEN term_months = 3 THEN 36
WHEN term_months = 4 THEN 48
WHEN term_months = 5 THEN 60
ELSE term_months
END;

-- You can run two replace statements like this
-- Make sure to use TRIM so 36 months doesn't become '36 ' with a space at the end.
-- Don't forget to convert from year to months ( 3 should become 36)

SELECT DISTINCT application_date
FROM loan_stg2;

UPDATE loan_stg2
SET application_date = NULL
WHERE application_date = '';

UPDATE loan_stg2
SET application_date = NULL
WHERE application_date = 'TBD';

SELECT application_date,
CASE
	WHEN application_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN application_date 
    WHEN application_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(application_date,'%d-%m-%y')
    WHEN application_date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN STR_TO_DATE(application_date,'%m/%d/%y')
    WHEN application_date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{2}$' THEN STR_TO_DATE(application_date,'%m/%d/%y')
    WHEN application_date REGEXP '[^A-Za-z]{3}' THEN STR_TO_DATE(application_date,'%b %d,%y')
    END as application_date
FROM loan_stg2;

-- REGEXP checks the shape of the text. Start with ^ and end with $ inside of single quotes ''
-- Pay close attention to how the dates as formatted. dd/mm/yyyy, mm-dd-yyyy, mm dd yy are not the same

-- [0-9] is the range and {2} is the # of digits to return
 -- [A-Za-z] is the range. A-Z is any uppercase and a-z is any lower case. The {3} returns 3 characters, like Jan or Feb
		-- The # of digits you want returned can't exceed the lenght of the month. If 10 was selected above it would show up as NULL
        
-- STR_TO_DATE changes the datatype to date. STR_TO_DATE([column name], %m/ %d %y)
		-- The date format can vary. it could have a different order or different signs like / , -
-- make sure to match date formats at end (m,d,y) to the format of the cell, this is a common mistake the causes NULL
		-- %d-%m-%y is different order than %m/%d/%y, same with %y (2 digits) and %Y(4 digits)
        
        
SHOW WARNINGS;

-- got error code 1292
		-- Essentially the formatting for the dates was wrong on one column (there was a %y when it should had been %Y
        -- and '[^A-Za-z]{3}' should be '^[A-Za-z]{3}'
-- Run this to see warnings from a select statement
-- It lists every value that triggered a warning, along with the reason
-- Useful if an UPDATE statement doesn't work, but the select statement does

UPDATE loan_stg2
SET application_date =
CASE
	WHEN application_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN application_date 
    WHEN application_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(application_date,'%d-%m-%y')
    WHEN application_date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN STR_TO_DATE(application_date,'%m/%d/%y')
    WHEN application_date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{2}$' THEN STR_TO_DATE(application_date,'%m/%d/%y')
    WHEN application_date REGEXP '[^A-Za-z]{3}' THEN STR_TO_DATE(application_date,'%b %d,%y')
    END;

-- The code above has three issues the came from show warnings statement:
-- 1. Line 344 should have %Y instead since we want to return 4 values for the year
-- 2. There is no datetime value for anything '00/00/0000', while we got rid of blanks we need to include this in the query
-- 3. BE CAREFUL where the ^ is in line 346. ^A-Za-z means "not a letter", the ^ should be outside brackets

UPDATE loan_stg2
SET application_date =
CASE
	WHEN application_date IN ('00/00/0000', 'TBD') THEN NULL
	WHEN application_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN application_date 
    WHEN application_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(application_date,'%d-%m-%y')
    WHEN application_date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN STR_TO_DATE(application_date,'%m/%d/%Y')
    WHEN application_date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{2}$' THEN STR_TO_DATE(application_date,'%m/%d/%y')
    WHEN application_date REGEXP '^[A-Za-z]{3}' THEN STR_TO_DATE(application_date,'%b %d,%Y')
    END;
    
SELECT * 
FROM loan_stg2;

-- now for the status column

SELECT DISTINCT TRIM(status)
FROM loan_stg2
;
-- There should only be three distinct status, but
-- there were some entry errors with mispelled words
SELECT CASE
	WHEN LOWER(TRIM(status)) IN ('approved', 'aprvd') THEN 'Approved'
    WHEN LOWER(TRIM(status)) IN ('pend', 'pending') THEN 'Pending'
    WHEN LOWER(TRIM(status)) IN ('declined', 'denied') THEN 'Denied'
    ELSE status
    END as Status
FROM loan_stg2;

-- First this query runs all the values as a lower case
	-- rather than running different queries for 'APPROVED' and 'approved'
    -- It makes all values have the same case so it's easier to fix
-- which then allows us to change the different status categories to have only 3
-- Doing it this way also allows us to change it to Proper case
-- So 'approved' and 'Aprvd' become 'Approved'

UPDATE loan_stg2
SET status = CASE
	WHEN LOWER(TRIM(status)) IN ('approved', 'aprvd') THEN 'Approved'
    WHEN LOWER(TRIM(status)) IN ('pend', 'pending') THEN 'Pending'
    WHEN LOWER(TRIM(status)) IN ('declined', 'denied') THEN 'Denied'
    ELSE status
    END;
    
-- For employement_length, we want digits here only and now texts
-- We also want to get rid of any blank values and make them NULL

SELECT DISTINCT employment_length
FROM loan_stg2;

UPDATE loan_stg2
SET employment_length= NULL
WHERE employment_length = '';

UPDATE loan_stg2
SET employment_length = 0
WHERE employment_length LIKE '< 1 year';

SELECT TRIM(REPLACE(REPLACE((employment_length), 'years' , ''), '+ yrs', ''))
FROM loan_stg2;

UPDATE loan_stg2
SET employment_length= TRIM(REPLACE(REPLACE((employment_length), 'years' , ''), '+ yrs', ''));

-- On the credit score column, values can only range from 300 to 850. 
-- anything lower than 300 or higher than 850 must be some sort of entry error or import error
-- We can set these values to NULL for now

SELECT credit_score 
FROM loan_stg2
WHERE credit_score <300 OR credit_score > 850;

-- We have multiple entries the need to be set to NULL
-- 1200, 0, N/A

UPDATE loan_stg2
SET credit_score = NULL
WHERE credit_score <300 OR credit_score > 850;

-- Next we move on to annual_income
-- 
SELECT *
FROM loan_stg2;

UPDATE loan_stg2
SET annual_income = NULL
WHERE annual_income = '';

SELECT REPLACE(REPLACE(TRIM(annual_income), ',', ''), '$', '')
FROM loan_stg2;

UPDATE loan_stg2
SET annual_income =  REPLACE(REPLACE(TRIM(annual_income), ',', ''), '$', '');

-- This query gets rid of all '$' and ','
-- Next there are some abnormal values like '9999999' or Negatives
-- These were likely entry or import errors
-- Some loans with '9999999' as annual_income don't necessarly make sense
		-- For example, why would someone with an income that high take out a loan for $8500 (loan id 1477)

SELECT DISTINCT(annual_income)
FROM loan_stg2
ORDER BY annual_income;

SELECT *
FROM loan_stg2
WHERE annual_income >= 9999999;

UPDATE loan_stg2
SET annual_income = ABS(annual_income);

UPDATE loan_stg2
SET annual_income = null
WHERE annual_income = 9999999;

-- Lastly we change the datatype
-- Now the all date has been standardized, changing the datatype can allow us
-- Math works. You can’t average or sum text, and MAX() on text sorts alphabetically ('9' beats '100').
-- Sorting and comparing are correct. Numbers sort numerically and dates chronologically.
-- Date functions work. You can pull the year or month, or calculate the time between dates.
-- Bad data gets blocked. A DATE or INT column rejects values like N/A.

ALTER TABLE loan_stg2
MODIFY loan_amount DECIMAL (10,2),
MODIFY interest_rate DECIMAL (5,2),
MODIFY term_months INT,
MODIFY application_date DATE,
MODIFY annual_income INT,
MODIFY credit_score INT,
MODIFY employment_length INT
;

##-- 4. Deal with NULLs and Remove uneeded data
-- We can't populate null values with the current data available
-- All rows and columns with NULL values need those values to be looked up
	-- for example, we can't populate the interest rate, annual income, or loan amount
    -- Just from the given data

-- We can however get rid of the row_num column as it was only used as a tool to help remove duplicates.

ALTER TABLE loan_stg2
DROP COLUMN row_num;

SELECT *
FROM loan_stg2;

##-- Final check 
-- Here we are just checking if there are any blanks or if anything else needs to be cleaned.
-- We aren't checking every column of every row, but a quick glance to see if anything was missed

SELECT DISTINCT loan_id
FROM loan_stg2;

SELECT DISTINCT state
FROM loan_stg2;

SELECT DISTINCT loan_amount
FROM loan_stg
ORDER BY 1;

SELECT DISTINCT interest_rate
FROM loan_stg2
ORDER BY 1 DESC;

SELECT DISTINCT term_months
FROM loan_stg2
ORDER BY 1;

SELECT DISTINCT loan_purpose
FROM loan_stg2;


SELECT DISTINCT application_date
FROM loan_stg2
ORDER BY 1;

SELECT DISTINCT status
FROM loan_stg2;

SELECT DISTINCT credit_score
FROM loan_stg2;

SELECT DISTINCT annual_income
FROM loan_stg2
ORDER BY 1;

SELECT DISTINCT employment_length
FROM loan_stg2;

SELECT COUNT(*)
FROM loan_stg;
-- There are 546 rows

SELECT COUNT(*)
FROM loan_stg2;
-- Noe we have 520 rows, 26 of them were dropped/ duplicates

SELECT Count(loan_id)
FROM loan_stg;

SELECT *
FROM loan_stg2;

-- Q1 (avg rates by term months)
SELECT CASE
	WHEN term_months = 24 Then 24
	WHEN term_months = 36 Then 36
    WHEN term_months = 48 Then 48
    WHEN term_months = 60 Then 60
    END as months,
    ROUND(AVG(interest_rate),2) as avg_interest,
    COUNT(*) as num_loan
FROM loan_stg2
GROUP BY months
ORDER BY months;


SELECT term_months,
    ROUND(AVG(interest_rate),2) as avg_interest,
    COUNT(*) as num_loan
FROM loan_stg2
GROUP BY term_months
ORDER BY term_months;


-- Q3 (credit_score)
SELECT CASE
	WHEN credit_score BETWEEN 300 and 579 THEN '300-579'
    WHEN credit_score BETWEEN 580 and 669 THEN '580-669'
    WHEN credit_score BETWEEN 670 and 739 THEN '670-739'
    WHEN credit_score BETWEEN 740 and 850 THEN '740-850'
    END as credit_band,
    ROUND(AVG(loan_amount),2) as avg_loan,
    COUNT(*) as num_loan
FROM loan_stg2
GROUP BY credit_band
ORDER BY credit_band;

-- Q3(interest_rates)

SELECT CASE
	WHEN interest_rate BETWEEN 5.50 and 9.99 THEN '5.50-9.99'
    WHEN interest_rate BETWEEN 10 and 14.99 THEN '10-14.99'
    WHEN interest_rate BETWEEN 15 and 19.99 THEN '15-19.99'
    WHEN interest_rate BETWEEN 20 and 24.50 THEN '20-24.50'
    END as interest_band,
    ROUND(AVG(loan_amount),2) as avg_loan,
    COUNT(*) as num_loan
FROM loan_stg2
GROUP BY interest_band
ORDER BY interest_band;

SELECT CASE
	WHEN credit_score BETWEEN 300 and 579 THEN '300-579'
    WHEN credit_score BETWEEN 580 and 669 THEN '580-669'
    WHEN credit_score BETWEEN 670 and 739 THEN '670-739'
    WHEN credit_score BETWEEN 740 and 850 THEN '740-850'
    END as credit_band,
    ROUND(AVG(interest_rate),2) as avg_interest,
    COUNT(*) as num_loan
FROM loan_stg2
GROUP BY credit_band
ORDER BY credit_band;


-- Q4 average loan by state

SELECT state,
    ROUND(AVG(loan_amount),2) as avg_loan,
    ROUND(AVG(interest_rate),2) as avg_interest,
    COUNT(*) as num_loan
FROM loan_stg2
GROUP BY state
ORDER BY avg_loan;

-- Q5 estimated interest income on approved loans
SELECT *
FROM loan_stg2
WHERE status = 'Approved';

WITH est_interest AS (
SELECT loan_id, (loan_amount*(interest_rate/ 100)*(term_months/ 12)) AS est_interest_income
FROM loan_stg2 
WHERE status = 'Approved'
)
SELECT ROUND(SUM(est_interest_income), 2) AS total_est_interest,
COUNT(est_interest_income) AS loans_included,
COUNT(*) AS approved_loans
FROM est_interest;

-- This query assumes simple interest  and that every loan is repaid in full. 
-- It ignores defaults and the fact that real loans are paid down over time, but
-- It is useful for an estimate



-- Q6 annual income and avg loan amount
SELECT DISTINCT(annual_income)
FROM loan_stg2
ORDER by 1;

SELECT CASE
	WHEN annual_income BETWEEN 25000 and 49999 THEN '25k-49k'
    WHEN annual_income BETWEEN 50000 and 99999 THEN '50k-99k'
    WHEN annual_income BETWEEN 100000 and 160000 THEN '100k-160k'
    END as income_band,
    ROUND(AVG(loan_amount),2) as avg_loan,
    COUNT(*) as num_loan
FROM loan_stg2
GROUP BY income_band
ORDER BY avg_loan;
