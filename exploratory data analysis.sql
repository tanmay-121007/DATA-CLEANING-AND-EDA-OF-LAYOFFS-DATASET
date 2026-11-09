-- exploratory data analysis

select * from layoffs_staging_2;

select max(total_laid_off) from layoffs_staging_2;

-- Looking at Percentage to see how big these layoffs were
select max(total_laid_off), max(percentage_laid_off) from layoffs_staging_2
where percentage_laid_off is not null;

-- Which companies had 100 percent of they company laid off
select * from layoffs_staging_2 
where percentage_laid_off = 1;

-- if we order by funds_raised_millions we can see how big some of these companies were
select * from layoffs_staging_2 
where percentage_laid_off = 1
order by funds_raised_millions desc;

-- Companies with the biggest Layoff on a single day
select company, total_laid_off,`date` from layoffs_staging_2
order by 2 desc
limit 5;

-- Companies with the most Total Layoffs
select company, sum(total_laid_off) from layoffs_staging_2 
group by company
order by 2 desc
limit 10;

-- by location 
select location, sum(total_laid_off) from layoffs_staging_2 
group by location
order by 2 desc
limit 10;

-- by country 
select country, sum(total_laid_off) from layoffs_staging_2 
group by country
order by 2 desc;

-- by industry
select industry, sum(total_laid_off) from layoffs_staging_2 
group by industry
order by 2 desc;

-- by stage 
select stage, sum(total_laid_off) from layoffs_staging_2 
group by stage
order by 2 desc;

-- by year 
select year(`date`), sum(total_laid_off) from layoffs_staging_2
group by year(`date`)
order by 1 asc;

-- rolling total of layoffs per month
select substring(`date`,1,7) as months, sum(total_laid_off) as total_laid_off
from layoffs_staging_2
where substring(`date`,1,7) is not null
group by substring(`date`,1,7)
order by 1 asc;

-- now use it in a CTE so we can query off of it
with months_cet as 
(
select substring(`date`,1,7) as months, sum(total_laid_off) as total_laid_off
from layoffs_staging_2
where substring(`date`,1,7) is not null
group by substring(`date`,1,7)
order by 1 asc
)
select months, total_laid_off, sum(total_laid_off) over(order by months asc) as rolling_total_laid_off
from months_cet
order by months asc;


-- ranking companies according to the total layoffs each year

with company_year as 
(
select company, year(`date`) as year, sum(total_laid_off) as total_laid_off from layoffs_staging_2 
group by company, year(`date`)
),
company_year_rank as 
(
select *, 
dense_rank() over(partition by year order by total_laid_off desc) as ranking
from company_year
where year is not null
)
select * from company_year_rank
where ranking <= 5; 