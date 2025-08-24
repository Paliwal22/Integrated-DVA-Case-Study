--Q1.Create a database called 'seafoodkart' in the SQL server 
create database seafoodkart;

USE seafoodkart;

--	Q2.Q. Import all five csv files (data sets) into SQL server under seafoodkart database
SELECT TOP 5 * FROM campaign_identifier;
select top 5 *from event_identifier;
select top 5 * from events;
select top 5 * from page_heirarchy;
select top 5 * from users;

--Q3.Update all tables with appropriate data types (convert all the columns into appropriate data types specially date related columns) - (25 Marks)

--a. Update the users table by modifying the start_date column to be a date data type
ALTER TABLE users ALTER COLUMN start_date DATE;

--b.. Update the events table by modifying event_time column to be a datetime data type.
ALTER TABLE events ALTER COLUMN event_time datetime;

--c.Update the  Campaign Identifier  table by modifying start_date, end_date columns to be a date data type.
ALTER TABLE campaign_identifier ALTER COLUMN start_date  date
ALTER TABLE campaign_identifier  ALTER COLUMN end_date DATE ;


--Q4.What is the count of records in each table?

--Begin
SELECT COUNT (*) AS COUNT_campaign_identifier FROM campaign_identifier;
--
select COUNT (*) AS COUNT_event_identifier from event_identifier;
---
select COUNT (*) AS COUNT_events from events;
--
select COUNT (*) AS COUNT_page_heirarchy from page_heirarchy;
--
select COUNT (*) AS COUNT_users from users

--end
--Q5. Create combined table of all the five tables by joining these tables. 
--The final table name should be 'Final_Raw_Data' in the data base

--BEGIN
SELECT * INTO Final_Raw_Data FROM (
	SELECT * FROM (
    SELECT A.*,B.event_name,C.page_name,C.product_category,
	C.product_id,D.user_id,D.start_date,E.campaign_id,
	E.campaign_name,E.end_date
	FROM events AS A
  FULL JOIN
	event_identifier AS B
    ON A.event_type = B.event_type
 FULL JOIN
    dbo.page_heirarchy AS C
    ON A.page_id = C.page_id
FULL JOIN 
	dbo.users AS D
	ON A.cookie_id = D.cookie_id
FULL JOIN
	dbo.campaign_identifier AS E
	ON A.event_type = E.campaign_id) AS F ) AS N
--end

--	Q6.
--Q. create a new table (product_level_summary) which has the following details:
-- How many times was each product viewed? 
-- How many times was each product added to cart? 
-- How many times was each product added to a cart but not purchased (abandoned)? 
-- How many times was each product purchased?

SELECT * INTO product_level_summary FROM
(SELECT A.product_id,
      SUM(CASE WHEN A.event_name = 'Page View' THEN 1 ELSE 0 END) AS Viewed,
	  SUM(CASE WHEN A.event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS Added_to_Cart,
	  SUM(CASE WHEN A.event_name = 'Purchase' THEN 1 ELSE 0 END) AS Purchased,
	  SUM(CASE WHEN A.event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS Added_to_cart_but_not_purchased
	  FROM Final_Raw_Data AS A 
	  GROUP BY A.product_id
	  ) AS B 
--END
--Q7. create a new table (product_category_level_summary) which has the following details:
--How many times was each product viewed? 
--How many times was each product added to cart? 
--How many times was each product added to a cart but not purchased (abandoned)? 
--How many times was each product purchased?

--BEGIN
 SELECT * INTO product_category_level_summary FROM
 (SELECT A.product_category,
      SUM(CASE WHEN A.event_name = 'Page View' THEN 1 ELSE 0 END) AS Viewed,
	  SUM(CASE WHEN A.event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS Added_to_Cart,
	  SUM(CASE WHEN A.event_name = 'Purchase' THEN 1 ELSE 0 END) AS Purchased,
	  SUM(CASE WHEN A.event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS Added_to_cart_but_not_purchased
	  FROM dbo.Final_Raw_Data AS A
	  GROUP BY A.product_category) AS F
	  SELECT * FROM product_category_level_summary
--END


--Q8. Create a new table 'visit_summary' that has 1 single row for every unique visit_id record and has the following 10 columns:
--1. user_id
--2. visit_id 
--3. visit_start_time: the earliest event_time for each visit
--4. page_views: count of page views for each visit
--5. cart_adds: count of product cart add events for each visit 
--6. purchase: 1/0 flag if a purchase event exists for each visit 
--7. campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date 
--8. impression: count of ad impressions for each visit 
--9. click: count of ad clicks for each visit 
--10. cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)

--BEGIN
SELECT * INTO visit_summary FROM
(SELECT DISTINCT Z.user_id,Z.visit_id,Z.Visit_Start_Time,Z.page_views,Z.cart_adds,
Z.Purchase,Z.Impression,Z.Click,Y.campaign_name FROM (
SELECT A.user_id,A.visit_id,MIN(A.event_time) AS Visit_Start_Time,
COUNT(CASE WHEN A.event_name = 'Page View' THEN 1 ELSE 0 END) AS page_views,
COUNT(CASE WHEN A.event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS cart_adds,
CASE WHEN EXISTS(SELECT * FROM dbo.Final_Raw_Data WHERE visit_id = A.visit_id AND event_type = 3) THEN 1 ELSE 0 END AS Purchase,A.campaign_name,
COUNT(CASE WHEN A.event_name = 'Ad Impression' THEN 1 ELSE 0 END) AS Impression,
COUNT(CASE WHEN A.event_name = 'Ad Click' THEN 1 ELSE 0 END) AS Click,
STUFF((SELECT ',' + CAST(product_id AS VARCHAR(10))
        FROM FINAL_RAW_DATA
        WHERE visit_id = A.visit_id AND event_type = 2
        ORDER BY sequence_number
        FOR XML PATH('')), 1, 1, '') AS cart_product
 FROM dbo.Final_Raw_Data AS A
 GROUP BY A.user_id,A.visit_id,A.campaign_name) AS Z
 INNER JOIN
 (SELECT B.campaign_name FROM dbo.Final_Raw_Data AS B
 WHERE B.event_time BETWEEN B.start_date AND B.end_date) AS Y
 ON Z.campaign_name =Y.campaign_name ) AS TBL
