-- DATA CLEANING !!

-- 1. Creating a backup of the raw data

SELECT * FROM layoffs;

CREATE TABLE world_layoffs.layoffs_staging 
LIKE world_layoffs.layoffs;

SELECT * FROM layoffs_staging;

INSERT INTO layoffs_staging 
SELECT * FROM world_layoffs.layoffs;

SELECT *
FROM world_layoffs.layoffs_staging
;

-- 2. Removing duplicates

SELECT *
FROM (
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`,
            stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
) duplicates
WHERE 
	row_num > 1;
    
    
-- ***** given below is an invalid query ***** 

WITH DELETE_CTE AS 
(
SELECT *
FROM (
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
) duplicates
WHERE 
	row_num > 1
)
DELETE
FROM DELETE_CTE
;

WITH DELETE_CTE AS (
	SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, 
    ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
	FROM world_layoffs.layoffs_staging
)
DELETE FROM world_layoffs.layoffs_staging
WHERE (company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, row_num) IN (
	SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, row_num
	FROM DELETE_CTE
) AND row_num > 1;

-- ***** given above is an invalid query *****

CREATE TABLE `layoffs_staging2` (
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

SELECT * FROM layoffs_staging2;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, 
	percentage_laid_off, `date`, stage, country, funds_raised_millions) 
AS row_num
FROM world_layoffs.layoffs_staging;

DELETE FROM layoffs_staging2 WHERE row_num>1;

SHOW VARIABLES LIKE 'sql_safe_updates';

SET SQL_SAFE_UPDATES = 0;

SELECT * FROM layoffs_staging2;

SELECT * FROM layoffs_staging2 WHERE row_num > 1;

-- 3. Standardizing data

SELECT * 
FROM world_layoffs.layoffs_staging2;

SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY industry;

SELECT *
FROM layoffs_staging2
WHERE industry like 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry like 'Crypto%';

SELECT * 
FROM layoffs_staging2;

SELECT DISTINCT country
FROM layoffs_staging2;

SELECT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
WHERE country LIKE 'United States.';

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country);

SELECT `date`, 
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Always do the below in a staging table and not the rw one.
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- 4. Handling missing values

SELECT * 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT * 
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

SELECT *
FROM layoffs_staging2
WHERE company LIKE 'airbnb%';

UPDATE world_layoffs.layoffs_staging2
SET industry = NULL
WHERE industry = '';

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL ;

SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL ;

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company LIKE 'Bally%';

-- At the point the missing values in the same company that had industry blank 
-- in some and filled in some are handled. 
-- Bally's doesn't come under this category.

-- 5. Removing irrelevant data

SELECT * 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT *
FROM world_layoffs.layoffs_staging2;

-- EDA (EXPLORATORY DATA ANALYSIS) !!

SELECT *
FROM layoffs_staging2;

SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

SELECT *
FROM layoffs_staging2
WHERE  percentage_laid_off = 1;

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE  percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

SELECT company, SUM(total_laid_off)
FROM layoffs_staging
GROUP BY company
ORDER BY 2 DESC
LIMIT 5;

SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

SELECT location, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY location
ORDER BY 2 DESC
LIMIT 10;

SELECT country, AVG(percentage_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(date)
ORDER BY 1 ASC;

SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 1 DESC
LIMIT 20;

SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

SELECT *
FROM layoffs_staging2;

SELECT SUBSTRING(`date`, 1, 7) AS `YEAR_MONTH`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `YEAR_MONTH`
ORDER BY 1 ASC;

WITH Rolling_Total AS 
(
SELECT SUBSTRING(`date`, 1, 7) AS `YEAR_MONTH`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `YEAR_MONTH`
ORDER BY 1 ASC
)
SELECT `YEAR_MONTH`, total_off, SUM(total_off) OVER (ORDER BY `YEAR_MONTH` ASC) AS rolling_total_layoffs
FROM Rolling_Total;

SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 ASC;

WITH Company_Year(company, years, total_laid_off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
)
SELECT *
FROM Company_Year;

WITH Company_Year2 AS 
(
  SELECT company, YEAR(date) AS years, SUM(total_laid_off) AS total_laid_off
  FROM layoffs_staging2
  GROUP BY company, YEAR(date)
)
, Company_Year_Rank AS 
(
  SELECT company, years, total_laid_off, DENSE_RANK() 
  OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
  FROM Company_Year2
)
SELECT *
FROM Company_Year_Rank
WHERE ranking <= 5
AND years IS NOT NULL
ORDER BY years ASC, total_laid_off DESC;






































