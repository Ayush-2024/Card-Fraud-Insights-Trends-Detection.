Create database credit_card;
use credit_card;

-- Exploring Data Analysis
select * from creditcard;

select count(*) from creditcard;

-- Check the column and their Data Type
describe  creditcard;

 -- Identify missing or NULL values
select * from creditcard 
where amount is null; 

-- Count total transactions
 select count(*) as Total_Transaction from creditcard;
 
 select class, count(*) as Transaction from creditcard
 group by 1;
 
 -- Calculate the Percentage of Fraud Cases
 select round((count(case when class = 1 then 1 end) * 100.0 / count(*)),2) as fraud_percentage 
 from creditcard;
 
 -- Find the minimum, maximum, and average transaction amounts.
 select min(amount) as Min_Transaction , max(amount) as Max_Transaction, avg(amount) as Avg_Transaction from creditcard;
 
 -- Compare fraud vs. non-fraud transaction amounts
select class,round(sum(amount),2) as Total_Transaction from creditcard
group by 1;

-- Identify high-value fraud transactions
select max(amount) as fraud_max_transaction from creditcard
where class = 1;
 
 -- Top 1% amount of Transaction in fraud Transaction.
 with cte as (
select *,row_number()over(order by amount desc) as rnk from creditcard
where class = 1
)
select * from cte 
where rnk <= (SELECT COUNT(*) * 0.01 FROM creditcard 
where class = 1 );

-- Convert time column into hours/days
select * , floor(time / 3600) as  Hours , floor(time / 3600*24) as Days from creditcard;

-- Find peak fraud hours (most frauds occur at what time?)
WITH cte AS (
    SELECT *, FLOOR((Time - (SELECT MIN(Time) FROM creditcard)) / 3600) % 24 AS Hours 
    FROM creditcard
)
SELECT Hours, COUNT(*) AS Fraud_Transaction_Count
FROM cte
WHERE class = 1
GROUP BY 1
ORDER BY Fraud_Transaction_Count DESC;

-- Check fraud trend over different days
WITH cte AS (
    SELECT *, FLOOR(Time / 86400) AS Days 
    FROM creditcard
)
SELECT Days, COUNT(*) AS Fraud_Count 
FROM cte
WHERE class = 1
GROUP BY Days
ORDER BY Fraud_Count DESC;

--  Identify the most common fraud transaction range (amount-wise)

SELECT 
    FLOOR(amount / 10) * 10 AS Amount_Range,
    COUNT(*) AS Fraud_count
FROM
    creditcard
WHERE
    class = 1
GROUP BY 1
ORDER BY Fraud_count DESC
LIMIT 5;

 -- Check if frauds occur in specific time slots more frequently
 with cte as 
 (select floor(time/3600) % 24 as Hours , count(*) as Fraud_cound from creditcard
 where class = 1
 group by 1
 order by Fraud_cound desc
 )
 select *,(case when Hours between 6 and 11 then 'Morning'
		 when Hours between 12 and 16 then 'Afternoon'
         when Hours between 17 and 23 then 'Night'
         else 'Late Night' 
         end
 ) as Time_slot from cte
 ;
 
 -- Find Transactions with Exact Same Amount & Time (Potential Automated Fraud)
 SELECT 
    floor(time/3600) % 24 as Hours,amount, 
    COUNT(*) AS occurrence 
FROM creditcard
WHERE class = 1
GROUP BY Time,amount
HAVING COUNT(*) > 1
ORDER BY occurrence DESC;

-- Check correlation between amount & fraud likelihood
SELECT 
    round((AVG(amount * class) - (AVG(amount) * AVG(class))) /
    (STD(amount) * STD(class)),2) AS correlation
FROM creditcard;

-- Group transactions by ranges (low, mid, high amounts) and check fraud probability
with cte as 
(select (case when amount <= 100 then 'Low'
             when amount between 101 and 500 then 'Medium'
             else 'High'
       end )as Amount_range, class from creditcard
)
select Amount_range,count(*) as Total_transaction,sum(class) as fraud_count,
round(100 * sum(class) / count(*), 2) as fraud_percentage
 from cte 
group by 1
order by fraud_percentage desc;      

-- Check if multiple transactions happen within a very short time 
WITH cte AS (
    SELECT *, 
           LAG(time) OVER (ORDER BY time) AS prev_time,
           time - LAG(time) OVER (ORDER BY time) AS time_diff
    FROM creditcard
)
SELECT * FROM cte
WHERE time_diff IS NOT NULL AND time_diff <= 10;

