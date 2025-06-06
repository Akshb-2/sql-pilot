-- Layoffs Data Processing Project

-- Step 1: Inspect Initial Data
SELECT * FROM layoffs_staging;

-- Step 2: Create Staging Table from Original Table Structure
CREATE TABLE layoffs_staging LIKE layoffs;

-- Step 3: Populate Staging Table with Data from Original Table
INSERT INTO layoffs_staging
SELECT * FROM layoffs;

-- Step 4: Identify Duplicate Records Using Window Functions
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Step 5: Filter Duplicate Records for Specific Company (Example: 'Casper')
WITH Duplicate_cte AS (
  SELECT *,
  ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
  FROM layoffs_staging
)
SELECT * FROM Duplicate_cte
WHERE company = 'Casper';

-- Step 6: Create Cleaned Staging Table with Row Number Column
CREATE TABLE layoffs_staging2 (
  company TEXT,
  location TEXT,
  industry TEXT,
  total_laid_off INT DEFAULT NULL,
  percentage_laid_off TEXT,
  `date` TEXT,
  stage TEXT,
  country TEXT,
  funds_raised_millions INT DEFAULT NULL,
  row_num INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Step 7: Insert Data with Duplicate Row Numbering into Cleaned Table
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Step 8: Query Data for a Specific Company (Case-Insensitive Example)
SELECT * FROM layoffs_staging2 WHERE company = 'casper';

-- Step 9: Trim Leading/Trailing Spaces from Company Names
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Step 10: Explore Distinct Locations and Industries
SELECT DISTINCT location FROM layoffs_staging2 ORDER BY location;
SELECT DISTINCT industry FROM layoffs_staging2 ORDER BY industry;

-- Step 11: Normalize Industry Names (e.g., set 'Crypto' industry)
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Step 12: Clean Country Field (Remove trailing dots for 'United States')
UPDATE layoffs_staging2
SET country = TRIM('.' FROM country)
WHERE country LIKE 'united states%';

-- Step 13: Convert `date` Field to Proper DATE Data Type
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- Step 14: Verify Data for Specific Company Example
SELECT * FROM layoffs_staging2 WHERE company LIKE 'airbnb';

-- Step 15: Handle Missing Industry Values
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Step 16: Fill Missing Industry Data by Joining on Company
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2 ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;

-- Step 17: Remove Records Missing Layoff Counts and Percentages
DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;
