-- energy analysis project
CREATE TABLE energy_analysis (
	hour_of_day smallint,
	datetime_start timestamp,
	solar_generation_kwh numeric(10,8),
	electricity_usage_kwh numeric(10,8)
);
select * from energy_analysis;

alter table energy_analysis
alter column electricity_usage_kwh
type numeric(20,8);

alter table energy_analysis
alter column solar_generation_kwh
type numeric(20,8);

COPY energy_analysis
FROM 'C:\Users\user\Documents\DATA_ANALYSIS\SQL\CSV\energy_analysis_data.csv'
WITH (FORMAT CSV, HEADER);

-- How much solar electricity is generated each day?
SELECT 
    DATE_TRUNC('day', datetime_start) AS day,
    SUM(solar_generation_kwh) AS total_solar_generation
FROM 
    energy_analysis
GROUP BY 
    DATE_TRUNC('day', datetime_start)
ORDER BY 
    day;

-- How does electricity usage vary throughout the day?
SELECT 
    hour_of_day,
    AVG(electricity_usage_kwh) AS avg_usage
FROM 
    energy_analysis
GROUP BY 
    hour_of_day
ORDER BY 
    hour_of_day;

-- How much excess solar electricity is available for storage?
SELECT 
    DATE_TRUNC('day', datetime_start) AS day,
    SUM(solar_generation_kwh - electricity_usage_kwh) AS excess_solar
FROM 
    energy_analysis
GROUP BY 
    DATE_TRUNC('day', datetime_start)
ORDER BY 
    day;

-- What are the potential savings or benefits from using a battery storage system?
SELECT 
    DATE_TRUNC('day', datetime_start) AS day,
    SUM(CASE 
            WHEN solar_generation_kwh > electricity_usage_kwh THEN electricity_usage_kwh
            ELSE solar_generation_kwh
        END) AS energy_used_directly,
    SUM(CASE 
            WHEN solar_generation_kwh > electricity_usage_kwh THEN solar_generation_kwh - electricity_usage_kwh
            ELSE 0
        END) AS energy_stored_in_battery
FROM 
    energy_analysis
GROUP BY 
    DATE_TRUNC('day', datetime_start)
ORDER BY 
    day;

-- check for missing values
select
	count(*) as total_rows,
	sum(case when hour_of_day is null then 1 else 0 end) as missing_hour_of_day,
	sum(case when datetime_start is null then 1 else 0 end) as missing_datetime_start,
	sum(case when solar_generation_kwh is null then 1 else 0 end) as missing_solar_generation_kwh,
	sum(case when electricity_usage_kwh is null then 1 else 0 end) as missing_electricity_usage_kwh
from energy_analysis;

-- check for data consistency in hour_of_day(should be within a range of 0 to 23)
select *
from energy_analysis
where hour_of_day < 0 or hour_of_day > 23;

-- check for data consistency in datatime_start (should have valid timestamps)
select *
from energy_analysis
where datetime_start is null or datetime_start::text !~ '^\d{4}-\d{2} \d{2}:\d{2}:\d{2}$';

select *
from energy_analysis
where to_char(datetime_start, 'yyyy-mm-dd hh24:mi:ss') != datetime_start::text;

-- check for outliers in solar_generation_kwh and electricity_usage_kwh
select
	min(solar_generation_kwh) as min_solar_generation_kwh,
	max(solar_generation_kwh) as max_solar_generation_kwh,
	min(electricity_usage_kwh) as min_electricity_usage_kwh,
	max(electricity_usage_kwh) as max_electricity_usage_kwh
from energy_analysis;

-- check for duplicate rows
select
	hour_of_day,
	datetime_start,
	solar_generation_kwh,
	electricity_usage_kwh,
	count(*)
from energy_analysis
group by hour_of_day, datetime_start, solar_generation_kwh, electricity_usage_kwh
having count(*) > 1;

-- check for overlapping time periods
select
	datetime_start,
	count(*)
from energy_analysis
group by datetime_start
having count(*) > 1

-- during which hour of the day does electricity usage peak
select hour_of_day, max(electricity_usage_kwh) as peak_usage
from energy_analysis
group by hour_of_day
order by peak_usage desc
limit 1;

-- how does daily solar generation compare to daily eleectricity usage(how much solar energy is consumed directly versus stored or unused energy)
select
	date_trunc('day', datetime_start) as day,
	sum(solar_generation_kwh) as total_solar_generated,
	sum(electricity_usage_kwh) as total_electricity_used,
	(sum(solar_generation_kwh)-sum(electricity_usage_kwh)) as net_solar
from energy_analysis
group by day
-- having (sum(solar_generation_kwh)-sum(electricity_usage_kwh)) > 1
order by day;

-- calculate the electricity bought by subtracting solar generation from electricity usage.
SELECT 
    hour_of_day,
    datetime_start,
    electricity_usage_kwh,
    solar_generation_kwh,
    GREATEST(electricity_usage_kwh - solar_generation_kwh, 0) AS electricity_bought_kwh
FROM 
    energy_analysis;

-- calculate the excess solar generation by subtracting electricity usage from solar generation.
SELECT 
    hour_of_day,
    datetime_start,
    electricity_usage_kwh,
    solar_generation_kwh,
    GREATEST(solar_generation_kwh - electricity_usage_kwh, 0) AS excess_solar_generation_kwh
FROM 
    energy_analysis;

