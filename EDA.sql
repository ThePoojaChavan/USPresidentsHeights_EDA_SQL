/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [order]
      ,[name]
      ,[height(cm)]
  FROM [US_Presidents_Heights].[dbo].[Heights]
  order by [height(cm)]

-- The dataset is small, with just 40-45 rows and 3 columns: id , name, height in cm)
  SELECT
      [height(cm)]
  FROM [dbo].[Heights]

--Summary Statistics (Avg, Min, Max, Std Deviation)
    SELECT
      round(avg([height(cm)]),0) as Avg_Height, 
	  round(STDEV([height(cm)]),0) as StDev_Height,
	  min([height(cm)]) as Min_Height,
	  max([height(cm)]) as Max_Height
  FROM [dbo].[Heights]

--Summary Statistics (Mode)- The most common height
--'With ties' will take into account bimodal or multimodal distribution as well
SELECT
    top (1)  with ties [height(cm)], 
	count([height(cm)]) as Mode_Height 
FROM [dbo].[Heights]
group by [height(cm)]
order by count([height(cm)]) desc

--Computing Quartiles (1st , 2nd/Median and 3rd)
 select 
	PERCENTILE_CONT(.25)  within group (order by   [height(cm)]) over() "Q1 Height",
	PERCENTILE_CONT(.50)  within group (order by   [height(cm)]) over() "Q2 or Median Height",
	PERCENTILE_CONT(.75)  within group (order by   [height(cm)]) over() "Q3 Height"
FROM [dbo].[Heights]

--Distribution is Skewed to left as mean<median<mode
 /*
 Mean Height: 180 cm
 Median Height: 182 cm
 Mode Height: 183 cm
 */

--Creating Frequency Distribution Table aka Histogram
 with Hist as
 (	select	[height(cm)],
			Case
				When  [height(cm)]<170 then 'Below 170 cm'
				When  [height(cm)]>=170 and  [height(cm)]<175 then 'Between 170 - 175 cm'
				When  [height(cm)]>=175  and [height(cm)]<180 then 'Between 175 - 180 cm'
				When  [height(cm)]>=180  and [height(cm)]<185 then 'Between 180 - 185 cm'
				When  [height(cm)]>=185  and [height(cm)]<190 then 'Between 185 - 190 cm'
				else 'More than 190 cm'
			end as Age_Bins
	FROM [dbo].[Heights]
 )
 select 
	Age_Bins, 
	count(Age_Bins) as Frequency
 from Hist
 group by Age_Bins
 order by Age_Bins

 select distinct [height(cm)]
 from [dbo].[Heights]
 
 
 insert into [dbo].[Heights] values (101,'Fictional1',182);

 insert into [dbo].[Heights] values (102,'Fictional2', 182);

 insert into [dbo].[Heights] values (103,'Fictional3', 182);

--Outlier Detection through ORDER BY, RANGE, Z-Score and IQR Fences
--1) ORDER BY
 SELECT [name],
		[height(cm)]
  FROM [US_Presidents_Heights].[dbo].[Heights]
  order by [height(cm)] desc

--2) RANGE (Height Range is 30 cm)
  SELECT max([height(cm)])- min([height(cm)]) as Height_range
  FROM [US_Presidents_Heights].[dbo].[Heights]

--3) Z-Score (There are no values which are below/above 3 sd, hence no outliers. But as Z-scores are calculated from mean, which is 
--subsceptible to outliers, this menthod is not a very effective way.
with zseries as
 (
	 select [height(cm)]  as Height
	 FROM dbo.Heights
 ),
 zstats as
 (	
	select 
		round(avg([height(cm)]),0) as zseries_mean,
		round(stdev([height(cm)]),0) as zseries_stdev
	from dbo.Heights
 )
select  zseries_mean,
round((Height- zseries_mean) /zseries_stdev,2) as Age_zScore
from
zseries,
zstats

/*where  (Height-zseries_mean)/zseries_stdev >3
or
(Height-zseries_mean)/zseries_stdev<-3
order by Height*/


--4) IQR Fences (There are no Outliers/ Anomalies in this dataset). Trusted way to detect outliers
 with Quart as
 (
  select 
	[height(cm)],
	PERCENTILE_CONT(.25)  within group (order by [height(cm)]) over() Q1,
	PERCENTILE_CONT(.75)  within group (order by [height(cm)]) over() Q3
 FROM [dbo].[Heights]
 )
 select [height(cm)] as Height, Q1 , Q3 , Q3-Q1 as IQR
 from Quart
 where
 [height(cm)]<= Q1 - (1.5*(Q3-Q1))
 or 
  [height(cm)]>= Q3 + (1.5*(Q3-Q1))

 commit
 
--NTILE (We find that each bucket contains equal number of values)
with ctile_height
as
(
select 
	[height(cm)], 
	ntile(4) over (order by [height(cm)])as buckets
from [dbo].[Heights]
)
select buckets, count(*)
from ctile_height
group by buckets

