CREATE SCHEMA `Capstone SQL`;


CREATE TABLE `Capstone SQL`.`Amazon_sales` (
`Invoice_id` VARCHAR(30) NOT NULL,
`branch` VARCHAR(10) NOT NULL,
`city` VARCHAR(30) NOT NULL,
`customer_type` VARCHAR(30) NOT NULL,
`gender` VARCHAR(10) NOT NULL,
`product_line` VARCHAR(100) NOT NULL,
`unit_price` DECIMAL(10,2) NOT NULL,
`quantity` INT NOT NULL,
`VAT` FLOAT NOT NULL,
`total` DECIMAL(10,2) NOT NULL,
`date` DATE NOT NULL,
`time` TIME(0) NOT NULL,
`payment_method` VARCHAR(30) NOT NULL,
`cogs` DECIMAL(10,2) NOT NULL,
`gross_margin_percentage` FLOAT NOT NULL,
`gross_income` DECIMAL(10,2) NOT NULL,
`rating` FLOAT NOT NULL,
PRIMARY KEY (`Invoice_id`));


-- Creating column to see if it's morning, noon or evening
ALTER TABLE Amazon_sales
ADD COLUMN timeofday VARCHAR(30) NOT NULL;


SET SQL_SAFE_UPDATES = 0;


-- Adding values to timeofday column
UPDATE Amazon_sales
SET timeofday = CASE
	WHEN TIME(time) BETWEEN '05:00:00' AND '11:59:59' THEN 'Morning'
    WHEN TIME(time) BETWEEN '12:00:00' AND '16:59:59' THEN 'Noon'
    WHEN TIME(time) BETWEEN '17:00:00' AND '20:59:59' THEN 'Evening'
    ELSE 'Night'
END;


-- Adding column dayname
ALTER TABLE Amazon_sales
ADD COLUMN dayname VARCHAR(30) NOT NULL;


UPDATE Amazon_sales
SET dayname = DATE_FORMAT(date, '%a');


-- Adding column monthname
ALTER TABLE Amazon_sales
ADD COLUMN monthname VARCHAR(30) NOT NULL;


UPDATE Amazon_sales
SET monthname = DATE_FORMAT(date, '%b');


-- Counting cities
SELECT 
	count(DISTINCT(city))
FROM 
	Amazon_sales;

-- City-Branch association
SELECT
	DISTINCT(branch), city 
FROM 
	Amazon_sales;


-- Counting product line
SELECT 
	COUNT(DISTINCT(product_line)) 
FROM 
	amazon_sales;


-- Most frequent payment method
SELECT 
	payment_method, COUNT(payment_method) cnt 
FROM 
	amazon_sales 
GROUP BY 
	payment_method 
ORDER BY 
	cnt DESC 
LIMIT 
	1;


-- Product line with highest sales
SELECT 
	product_line 
FROM 
	(SELECT product_line, SUM(quantity) cnt FROM amazon_sales GROUP BY product_line ORDER BY cnt DESC LIMIT 1) flt;


-- Calculating revenue generated each month
SELECT 
	monthname, SUM(total) revenue 
FROM 
	amazon_sales 
GROUP BY 
	monthname;


-- Month when cost of goods sold reached its peak
SELECT 
	monthname 
FROM 
	(SELECT monthname, SUM(total) revenue FROM amazon_sales GROUP BY monthname ORDER BY revenue DESC LIMIT 1) flt;


-- Product line that generated the highest revenue
SELECT 
	product_line as highest_rev_product_line 
FROM 
	(SELECT product_line, SUM(total) rev FROM amazon_sales GROUP BY product_line ORDER BY rev DESC LIMIT 1) flt;


-- City with highest revenue
SELECT 
	city AS high_rev_city 
FROM 
	(SELECT city, SUM(total) rev FROM amazon_sales GROUP BY city ORDER BY rev DESC LIMIT 1) flt;


-- Product line that incurred the highest VAT
SELECT 
	product_line AS high_tax_product 
FROM 
    (SELECT product_line, SUM(vat) tt FROM amazon_sales GROUP BY product_line ORDER BY tt DESC LIMIT 1) flt;


-- Adding a column to indicate if sales of product line are good or bad
ALTER TABLE amazon_sales
ADD COLUMN sales_category VARCHAR(30) NOT NULL;


-- Adding values to the column sales_category
SELECT 
	product_line, sales,
	CASE
		WHEN sales > (SELECT AVG(ts) FROM (SELECT product_line, SUM(total) ts FROM amazon_sales GROUP BY product_line) flt1) THEN 'Good'
        ELSE 'Bad'
	END sales_category
FROM
	(SELECT product_line, SUM(total) sales FROM amazon_sales GROUP BY product_line) flt;


-- Branch that exceeds the avg number of products sold
SELECT 
	branch, AVG(quantity) avg_quantity_sold
FROM 
	amazon_sales 
GROUP BY 
    branch
HAVING 
	avg_quantity_sold > (SELECT AVG(quantity) FROM amazon_sales);


-- Product line most frequently associated with each gender
SELECT 
	gender, product_line 
FROM
	(SELECT gender, product_line, SUM(quantity) sold,
	RANK() OVER (PARTITION BY gender ORDER BY SUM(quantity) DESC) rnk
	FROM amazon_sales GROUP BY gender, product_line) flt 
WHERE 
	rnk=1;


-- Average rating for each product line
SELECT 
	product_line, ROUND(AVG(rating), 2) avg_rating 
FROM 
	amazon_sales 
GROUP BY 
	product_line;
    

-- Sales occurence for each time of day every weekend
SELECT
	HOUR(time) hr, dayname, COUNT(quantity) sales_cnt
FROM
	amazon_sales
GROUP BY
	hr, dayname
HAVING
	dayname NOT IN ('sat', 'sun');
    
  
-- Customer type contributing the highest revenue
SELECT
	customer_type, SUM(total) rev
FROM
	amazon_sales
GROUP BY
	customer_type
ORDER BY 
	rev DESC
LIMIT
	1;
    

-- City with the highest VAT percentage
SELECT 
	city, ROUND(vt/tvt*100, 2) VAT_perc 
FROM
	(SELECT SUM(vat) tvt FROM amazon_sales) totvt,
	(SELECT city, SUM(vat) vt FROM amazon_sales GROUP BY city) cvt
ORDER BY 
	VAT_perc
LIMIT
	1;
    

-- Identifying the customers type with the highest VAT payments
SELECT
	customer_type, ROUND(SUM(vat), 2) tot_vat
FROM
	amazon_sales
GROUP BY
	customer_type
ORDER BY
	tot_vat DESC
LIMIT
	1;


-- Count of distinct customer types
SELECT
	COUNT(DISTINCT(customer_type)) cust_types
FROM
	amazon_sales;


-- Counting distinct payment methods
SELECT
	COUNT(DISTINCT(payment_method)) pay_methods
FROM
	amazon_sales;
    

-- Customer type occuring most frequently
SELECT
	customer_type, COUNT(customer_type) cust_count
FROM
	amazon_sales
GROUP BY
	customer_type
ORDER BY
	cust_count DESC
LIMIT
	1;


-- Predominant gender
SELECT
	gender, SUM(total) total_revenue
FROM
	amazon_sales
GROUP BY
	gender
ORDER BY
	total_revenue DESC;
    
    
-- Gender distribution within each branch
SELECT
	branch, gender, COUNT(gender) gender_count
FROM
	amazon_sales
GROUP BY
	branch, gender
ORDER BY
	branch, gender;
    
    
-- Time of day when customer provides most ratings
SELECT
	HOUR(time) day_time, ROUND(SUM(rating), 2) tot_rating
FROM
	amazon_sales
GROUP BY
	day_time
ORDER BY
	tot_rating DESC;


-- Time of day with highest customer ratings for each branch
WITH top_cust_branch_rating AS
	(SELECT
		branch, HOUR(time) day_time, ROUND(SUM(rating), 2) tot_rating,
		RANK() OVER (PARTITION BY branch ORDER BY SUM(rating) DESC) rnk
	FROM
		amazon_sales
	GROUP BY
		branch, day_time)
SELECT
	branch, day_time, tot_rating
FROM
	top_cust_branch_rating
WHERE
	rnk = 1;










