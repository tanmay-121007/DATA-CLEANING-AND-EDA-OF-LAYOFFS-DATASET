-- data cleaning 

-- the raw data --
select * from layoffs_raw;

-- creating a new tabel where we will do the cleaning --
create table layoffs_staging like layoffs_raw ;	
insert into layoffs_staging select * from layoffs_raw ;
select * from layoffs_staging ;

-- to check the duplicates and remove if any

--  to find out the duplicate data --
with duplicate_cte as
(
select *,row_number() 
over(partition by company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions) 
as row_num
from layoffs_staging 
)
select * from duplicate_cte
where row_num > 1; 

-- deleting from cte is not possible so we create another table --

CREATE TABLE `layoffs_staging_2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

insert into layoffs_staging_2 
select *,row_number() 
over(partition by company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions) 
as row_num
from layoffs_staging ;

select * from layoffs_staging_2;

-- this will show all the data that are duplicate--
select * from layoffs_staging_2
where row_num > 1 ;

-- this will delete the duplicated data
delete from layoffs_staging_2
where row_num > 1 ;


-- standardizing data 


-- checking the company column  --
select company,trim(company) from layoffs_staging_2;
/*	we notice that there are sum white spaces before and after
	entered data so we remove them	**/
update layoffs_staging_2
set company = trim(company);

select * from layoffs_staging_2;

-- checking if the industry column --
select distinct industry from layoffs_staging_2
order by 1; 
/*	we noticce crypto in indsutry column is used
	using 3 diffenent names so we standardze it	 */
update layoffs_staging_2
set industry = 'crypto'
where industry like 'crypto%';

-- checking the location column--
select distinct(location) from layoffs_staging_2
order by 1;
/*	everything looks good and clean	*/

-- checking the country column --
select distinct(country) from layoffs_staging_2
order by 1;
/*	we notice that United States is entered as United States.
so we standardize it */

update layoffs_staging_2
set country = trim(trailing'.'from country)
where country like 'United States%';

-- checking the date column --
select `date` from layoffs_staging_2;

select `date`, str_to_date(`date`,'%m/%d/%Y') from layoffs_staging_2;

update layoffs_staging_2
set `date` = str_to_date(`date`,'%m/%d/%Y');

/*we notice that the date is in string so we convert it into date formate */
alter table layoffs_staging_2
modify column `date` date;

 -- checking the industry column --
 select distinct industry from layoffs_staging_2;
 /* we notice there are two rows where industry is null or empty*/
 
 select * from layoffs_staging_2
 where industry is null or industry = "";
 /* we try to populate the enpty or null values as much as possible here */
 
select t1.company, t1.industry, t2.company, t2.industry from layoffs_staging_2 as t1
join layoffs_staging_2 as t2
	on t1.company = t2.company
	and t1.location = t2.location
where (t1.industry is null or t1.industry = '') and t2.industry is not null ;
/* from this we can populate the data in layoffs_staging_2 */

/* lets make all the empty values as null */
update layoffs_staging_2 
set industry = null
where industry = '';

update layoffs_staging_2 as t1
join layoffs_staging_2 as t2
	on t1.company = t2.company
set t1.industry = t2.industry 
where t1.industry is null  and t2.industry is not null ;
/* we have updated all the null valuees in the industry column */

-- removing the unwanted rows which cant be populated --
delete from layoffs_staging_2 where 
total_laid_off is null and percentage_laid_off is null ;

-- removing the unwanted columns --
alter table layoffs_staging_2 
drop column row_num;

select * from layoffs_staging_2;