# Loan Applications: SQL Data Cleaning and Analysis

A MySQL project that cleans a messy loan applications dataset and then analyzes it to answer five business questions.

**Tools:** MySQL 8.0, MySQL Workbench

## About the Data

The dataset was generated with the Claude AI model for practice. It is entirely made up and does not contain real customers. It holds loan applications for a fictional firm, with these columns: customer name, state, loan amount, interest rate, term (months), loan purpose, application date, status, annual income, credit score, and employment length.

The data was generated with intentional mistakes so it could be cleaned.

## Tables Used

| Table | Purpose |
|---|---|
| `loan_applications` | Raw imported data. Never modified. |
| `loan_stg` | Working copy of the raw data. |
| `loan_stg2` | Final cleaned table used for analysis. |

The original values can always be looked up in the raw table by `loan_id`.

## Issues Found

- 26 duplicate rows (checked, and the copies were identical)
- Inconsistent text: capitalization, extra spaces, and variant spellings (for example `Aprvd`, `Declined`, `Pend`)
- Numbers stored as text, with symbols like `$`, `%`, and commas
- Six different date formats, plus invalid dates like `00/00/0000`
- Mixed units in `term_months` (months vs. years) and `interest_rate` (decimals vs. percentages)
- Missing values written as blanks, `N/A`, `-`, and `NULL`
- Impossible values: negative amounts and incomes, credit scores of 0, 1200, and 9999, an income of 9,999,999, and loan amounts in the millions

## Cleaning Steps

1. Created two copies of the raw table and worked only on the copies.
2. Removed duplicates using `ROW_NUMBER()` partitioned by `loan_id`.
3. Trimmed spaces and standardized text: names and loan purposes in proper case, state names converted to two-letter abbreviations, and status variants merged into `Approved`, `Denied`, and `Pending`.
4. Removed `$`, `%`, and commas from number columns, and converted interest rates written as decimals (like 0.0893) to percentages (8.93).
5. Converted loan terms written in years to months.
6. Converted all date formats to a single `DATE` column using `STR_TO_DATE`.
7. Turned blanks and placeholders into `NULL`.
8. Changed column data types (`INT`, `DECIMAL`, `DATE`).

## Decisions and Assumptions

- **Negative values:** Used `ABS()` to make negative loan amounts and incomes positive, because a negative value didn't make sense. This is an assumption.
- **Loan amount outliers:** After cleaning, the highest normal loan was $59,500 and the next highest was $400,000 or more. I set everything above $60,000 to `NULL`. Dividing by 100 would produce realistic-looking values, but without checking the data source there is no way to know the real amounts.
- **Income of 9,999,999:** Set to `NULL`, since it looks like a placeholder and the real value is unknown.
- **Credit scores:** Valid scores run from 300 to 850, so values outside that range were set to `NULL`.
- **Employment length:** `< 1 year` was set to 0, because the exact length is unknown and decimals can't be assumed.

## Results

Rows in the raw data: **546**. Rows in the cleaned table: **520**. The 26 removed rows were duplicates, and every `loan_id` in the final table is unique.

## Findings

**1. Average interest rate by loan term**
Across all 520 applications, the average interest rate was 15.39% for 24-month terms, 14.55% for 36 months, 14.66% for 48 months, and 15.60% for 60 months. There is no straight relationship between term and rate. The 60-month term has the highest average, but the differences are small, and the four terms have similar numbers of loans. Another 17 loans have a missing term and a 13.22% average rate.

**2. Credit score and loan size**
Average interest rates stay within a small range across the credit bands, apart from the NULL group. Average loan amounts vary a little ($32,306 for 300-579, $28,407 for 580-669, $30,129 for 670-739, and $33,046 for 740-850), but there is no steady increase as credit scores rise. Two caveats: the lowest band has only 32 loans, and 83 loans (about 16%) have no credit score because I set impossible values to `NULL` during cleaning. The data shows no clear relationship between credit score and either loan amount or rate. Whether lower-score applicants apply less or get approved less often would need to be tested with the `status` column.

**3. State**
State has little to no relationship with loan amount or interest rate. Each state has a similar number of loans (in the 70s), with no NULLs. Average rates stay between about 14% and 15.8%. Average loan amounts rise slightly: PA $28,123, FL $29,159, NJ $29,297, OH $29,841, TX $31,469, CA $32,036, and NY $33,529. Cost of living could explain the small gap, but this data can't confirm it.

**4. Estimated interest income on approved loans**
Assuming simple interest, no defaults, and full on-time repayment, the estimated interest income is $2,515,788.10. This includes only 146 of the 174 approved loans. The other 28 were left out because of a missing amount, rate, or term, and some of those NULLs came from my own cleaning decisions (for example, setting loan amounts over $60,000 to `NULL`). So this figure is an underestimate.

**5. Annual income and loan amount**
There is no straight relationship between income and loan amount. Average loans by band: $32,632 for 25k-49k (76 loans), $29,568 for 50k-99k (173 loans), $30,120 for 100k-160k (210 loans), and $31,585 for loans with no income recorded (61 loans). The bands are different sizes, so the comparison is rough.

## Limitations

The data is randomly generated, so patterns found in it (or the lack of them) don't reflect how real lending works.

## Files

- `messy_loan_applications.csv`: the raw dataset
- SQL scripts: data cleaning and analysis queries
