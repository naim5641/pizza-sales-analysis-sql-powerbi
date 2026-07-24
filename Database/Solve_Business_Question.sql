-- Data cleaning 
-- step 1 : To check for duplicates
-- step 2 : Check for null VALUES
-- step 3 : Treating Null VALUES
-- step 4 : Handling Negative Values 
-- step 5 : Fixing Inconsistent date format & Invalid Dates 
-- step 6 : Fixing invalid Email Address
-- step 7 : Checking the data types 



SELECT
	MIN(CUSTID)
FROM
	CUSTOMERS
GROUP BY
	EMAIL
SELECT
	*
FROM
	CUSTOMERS
	--how to delete duplicate
DELETE FROM CUSTOMERS
WHERE
	CUSTID NOT IN (
		SELECT
			MIN(CUSTID)
		FROM
			CUSTOMERS
		GROUP BY
			EMAIL
	)
	-- how to delete duplicate using window function.
SELECT
	CUSTID
FROM
	(
		SELECT
			CUSTID,
			ROW_NUMBER() OVER (
				PARTITION BY
					EMAIL
				ORDER BY
					CUSTID
			) AS RN
		FROM
			CUSTOMERS
	) T
WHERE
	T.RN > 1


DELETE FROM CUSTOMERS
WHERE
	CUSTID IN (
		SELECT
			CUSTID
		FROM
			(
				SELECT
					CUSTID,
					ROW_NUMBER() OVER (
						PARTITION BY
							EMAIL
						ORDER BY
							CUSTID
					) AS RN
				FROM
					CUSTOMERS
			) T
		WHERE
			T.RN > 1
	)



	-- check for null values..


SELECT
	*
FROM
	CUSTOMERS
SELECT
	COUNT(*)
FROM
	CUSTOMERS
SELECT
	COUNT(*)
FROM
	CUSTOMERS
WHERE
	PHONE IS NOT NULL
	OR FIRST_NAME IS NOT NULL



	-- updated null value so that the report will not be broken.



UPDATE CUSTOMERS
SET
	PHONE = 0
WHERE
	PHONE IS NULL
UPDATE CUSTOMERS
SET
	FIRST_NAME = '-'
WHERE
	FIRST_NAME IS NULL



	-- handling negetive vlaues



SELECT
	*
FROM
	ORDER_DETAILS
SELECT
	*
FROM
	ORDER_DETAILS
WHERE
	ORDER_DETAILS.QUANTITY < 1
UPDATE ORDER_DETAILS
SET
	QUANTITY = 0
WHERE
	QUANTITY < 1



	-- fixing inconsistent date formates & Invalid dates 
	-- regular expression


SELECT
	ORDER_DATE
FROM
	ORDERS
WHERE
	ORDER_DATE !~ '^(19|20)\d\d-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$';



-- checking data type
/*

1. Orders Volume Analysis Queries

Stakeholder (Operation Manager);
"
We are trying to unserstand our order volume in details so we can
measure store performance and benhmark growth instead of just knowing the total number
of unique orders, i'd like a deeper breakdown: 

- what is the total number of unique orders placed so far?
- how has this order volume changed month over month year over year
- can we identify peak and off peak ordering days?
- how do order volumes vary by day of the week (e.g weekends vs weekdays)?
- what is the average number of orders per customers?
- who are our top repeat customer driving the order volume ?
- can you also project the expected order growth trend based on historical data?

"

*/



-- what is the total number of unique orders placed so far?



SELECT
	COUNT(DISTINCT ORDER_ID)
FROM
	ORDERS


-- how has this order volume changed month over month year over year
-- breakdown orders by month and year (group by extract (month/year from order_date))

WITH
	MONTHLY_ORDERS AS (
		SELECT
			DATE_TRUNC('month', ORDER_DATE) AS MONTH,
			COUNT(ORDER_ID) AS ORDER_COUNT
		FROM
			ORDERS
		GROUP BY
			DATE_TRUNC('month', ORDER_DATE)
	)
SELECT
	MONTH,
	ORDER_COUNT,
	LAG(ORDER_COUNT) OVER (ORDER BY MONTH) AS PREV_MONTH,
	ROUND(
		100.0 * (
			ORDER_COUNT - LAG(ORDER_COUNT) OVER (ORDER BY MONTH)
		) / NULLIF(
			LAG(ORDER_COUNT) OVER (ORDER BY MONTH),0),2) MOM_GROWTH_PCT
FROM
	MONTHLY_ORDERS
ORDER BY MONTH


	-- growth per year over year

WITH
	YEARLY_ORDERS AS (
		SELECT
			DATE_TRUNC('year', ORDER_DATE) AS YEAR,
			COUNT(ORDER_ID) AS ORDER_COUNT
		FROM
			ORDERS
		GROUP BY
			DATE_TRUNC('year', ORDER_DATE)
	)
SELECT
	YEAR,
	ORDER_COUNT,
	LAG(ORDER_COUNT) OVER (
		ORDER BY
			YEAR
	) AS PREV_YEAR,
	ROUND(
		100.0 * (
			ORDER_COUNT - LAG(ORDER_COUNT) OVER (ORDER BY YEAR)
		) / NULLIF(
			LAG(ORDER_COUNT) OVER(ORDER BYYEAR
			),
			0
		),
		2
	) MOM_GROWTH_PCT
FROM
	YEARLY_ORDERS
ORDER BY
	YEAR

	-- can we identify peak and off peak ordering days?	
SELECT
	TO_CHAR(ORDER_DATE, 'day') AS WEEKDAY,
	COUNT(DISTINCT ORDER_ID) AS TOTAL_ORDERS
FROM
	ORDERS
GROUP BY
	TO_CHAR(ORDER_DATE, 'day')
ORDER BY
	TOTAL_ORDERS DESC
	-- how do order volumes vary by day of the week (e.g weekends vs weekdays)?
WITH
	MONTHLY_ORDERS AS (
		SELECT
			DATE_TRUNC('month', ORDER_DATE) AS MONTH,
			CASE
				WHEN EXTRACT(
					DOW
					FROM
						ORDER_DATE
				) IN (5, 6) THEN 'Weekend'
				ELSE 'Weekday'
			END AS DAY_TYPE,
			COUNT(ORDER_ID) AS ORDER_COUNT
		FROM
			ORDERS
		GROUP BY
			DATE_TRUNC('month', ORDER_DATE),
			CASE
				WHEN EXTRACT(
					DOW
					FROM
						ORDER_DATE
				) IN (5, 6) THEN 'Weekend'
				ELSE 'Weekday'
			END
	)
SELECT
	MONTH,
	DAY_TYPE,
	ORDER_COUNT,
	LAG(ORDER_COUNT) OVER (
		PARTITION BY
			DAY_TYPE
		ORDER BY
			MONTH
	) AS PREV_MONTH,
	ROUND(
		100.0 * (
			ORDER_COUNT - LAG(ORDER_COUNT) OVER (
				PARTITION BY
					DAY_TYPE
				ORDER BY
					MONTH
			)
		) / NULLIF(
			LAG(ORDER_COUNT) OVER (
				PARTITION BY
					DAY_TYPE
				ORDER BY
					MONTH
			),
			0
		),
		2
	) AS MOM_GROWTH_PCT
FROM
	MONTHLY_ORDERS
ORDER BY
	DAY_TYPE,
	MONTH;

-- Weekend vs Weekday orders
SELECT
	CASE
		WHEN EXTRACT(
			DOW
			FROM
				ORDER_DATE
		) IN (0, 6) THEN 'Weekend'
		ELSE 'Weekday'
	END AS DAY_TYPE,
	COUNT(*) AS TOTAL_ORDERS
FROM
	ORDERS
GROUP BY
	DAY_TYPE;

-- Weekend vs Weekday sales

SELECT
	CASE
		WHEN EXTRACT(
			DOW
			FROM
				ORDER_DATE
		) IN (0, 6) THEN 'Weekend'
		ELSE 'Weekday'
	END AS DAY_TYPE,
	COUNT(*) AS TOTAL_ORDERS,
	SUM(AMOUNT) AS TOTAL_SALES,
	AVG(AMOUNT) AS AVG_ORDER_VALUE
FROM
	ORDERS
GROUP BY
	DAY_TYPE;

SELECT
	*
FROM
	CUSTOMERS


	-- average order per customer
SELECT
	ROUND(
		COUNT(DISTINCT ORDER_ID) * 1.0 / COUNT(DISTINCT CUSTID),
		2
	) AS AVG_ORDERS_PER_CUSTOMER
FROM
	ORDERS

-- repeat customer (with Frequency)

SELECT
	CUSTID,
	COUNT(DISTINCT ORDER_ID) AS ORDER_COUNT
FROM
	ORDERS
GROUP BY
	CUSTID
ORDER BY
	ORDER_COUNT DESC


	-- month over month growth using window function
	-- can you also project the expected order growth trend based on historical data?
	-- daily running orders (cumulative sum)


SELECT
	ORDER_DATE,
	COUNT(ORDER_ID) AS DAILY_ORDERS,
	SUM(COUNT(ORDER_ID)) OVER (
		ORDER BY
			ORDER_DATE
	) AS CUMULATIVE_ORDERS
FROM
	ORDERS
GROUP BY
	ORDER_DATE
ORDER BY
	ORDER_DATE;

--- daily growth trend
WITH
	DAILY_ORDERS AS (
		SELECT
			--to_char(order_date, 'day') as day_name,
			DATE_TRUNC('month', ORDER_DATE) AS MONTHLY,
			COUNT(*) AS ORDERS
		FROM
			ORDERS
		GROUP BY
			MONTHLY
	)


SELECT
	MONTHLY ORDERS,
	LAG(ORDERS) OVER (
		ORDER BY
			MONTHLY
	) AS PREV_DAY_ORDERS,
	ROUND(
		100.0 * (
			ORDERS - LAG(ORDERS) OVER (
				ORDER BY
					MONTHLY
			)
		) / NULLIF(
			LAG(ORDERS) OVER (
				ORDER BY
					MONTHLY
			),
			0
		),
		2
	) AS GROWTH_PCT
FROM
	DAILY_ORDERS
ORDER BY
	MONTHLY;



-- Trend Projection
WITH
	DAILY_ORDERS AS (
		SELECT
			ORDER_DATE,
			COUNT(*) AS ORDERS
		FROM
			ORDERS
		GROUP BY
			ORDER_DATE
	)
SELECT
	ORDER_DATE,
	ORDERS,
	ROUND(
		AVG(ORDERS) OVER (
			ORDER BY
				ORDER_DATE ROWS BETWEEN 6 PRECEDING
				AND CURRENT ROW
		),
		2
	) AS SEVEN_DAY_AVG
FROM
	DAILY_ORDERS;

"
2. Total revenue from Pizza Sales

we need to report monthly revenue to management.
can you calculate the total revenue generated from all pizza sales,
considering price * quantity from each order?

join order_details with pizzas and sum (price * quantity).
"


SELECT
	SUM(PRICE * QUANTITY) AS TOTAL_REVENUE
FROM
	ORDER_DETAILS OD
	JOIN PIZZAS P ON OD.PIZZA_ID = P.PIZZA_ID


"
3. Highest priced pizza


Our premium pizzas must be correctly priced. can you find out which 
pizza has the highest price on our menu and confirm its category 
and size?


"
SELECT
	PT.NAME,
	CONCAT('$ ', P.PRICE) AS PRICE
FROM
	PIZZAS P
	JOIN PIZZA_TYPES PT ON P.PIZZA_TYPE_ID = PT.PIZZA_TYPE_ID
GROUP BY 
	PT.NAME,P.PRICE
order by 
	P.PRICE DESC;

"
4. most common pizza size ordered

to optimize packaging and raw material supply, i need to know
pizza size (S, M, L, XL, XXL) is ordered the most

"
SELECT
	P.SIZE,
	COUNT(OD.ORDER_ID) AS TOTAL_ORDER
FROM
	ORDER_DETAILS OD
	JOIN PIZZAS P ON OD.PIZZA_ID = P.PIZZA_ID
GROUP BY
	P.SIZE
ORDER BY
	COUNT(OD.ORDER_ID) DESC
LIMIT
	1




"
5. top 5 most ordered pizza types
we want to promote our top selling pizzas. can you provide the top 
5 pizza types ordered by quantity , along with exact number of units sold?
"


SELECT
	P.PIZZA_ID,
	SUM(OD.QUANTITY) AS TOTAL_QTY
FROM
	ORDER_DETAILS OD
	JOIN PIZZAS P ON OD.PIZZA_ID = P.PIZZA_ID
	JOIN PIZZA_TYPES PT ON PT.PIZZA_TYPE_ID = P.PIZZA_TYPE_ID
GROUP BY
	P.PIZZA_ID
ORDER BY
	TOTAL_QTY DESC
LIMIT
	5



"

6.Total Quantity by pizza category.

we run promotions based on categories (classic, veggie, supreme,chicken,etc.).
can you calculate the total number of pizzas sold in each category
so we can plan targeted campaigns

--- join pizzas with pizza_types and sum quantities by category.

"



SELECT
	PT.CATEGORY,
	SUM(OD.QUANTITY) AS TOTAL_QTY
FROM
	PIZZAS AS P
	JOIN PIZZA_TYPES AS PT ON PT.PIZZA_TYPE_ID = P.PIZZA_TYPE_ID
	JOIN ORDER_DETAILS AS OD ON OD.PIZZA_ID = P.PIZZA_ID
GROUP BY
	PT.CATEGORY
ORDER BY
	TOTAL_QTY DESC



"
7. Orders by Hour of the day

when are customers ordering the most? Do they prefer lunch (12-2 pm)
evening(6-9 pm) or late-night? please give me a distribution
of orders by hour of the day so we can adjust staffing.

find hour from the order time in orders table and count frequency
"



SELECT
	*
FROM
	ORDERS
SELECT
	TO_CHAR(ORDER_TIME::TIME, 'HH24:00') AS ORDER_HOUR,
	COUNT(ORDER_ID) AS TOTAL_ORDER_BY_HOURLY
FROM
	ORDERS
GROUP BY
	ORDER_HOUR
ORDER BY
	TOTAL_ORDER_BY_HOURLY



"
8. Category - wise pizza distribution.

which categories (like veggie, chicken, supreme) dominate
our menu sales can you prepare a breakdown of orders per category
with percentage share?

"
SELECT
	PT.CATEGORY,
	COUNT(OD.ORDER_ID) AS TOTAL_ORDER,
	ROUND(
		COUNT(OD.ORDER_ID) * 100.0 / SUM(COUNT(OD.ORDER_ID)) OVER (),
		2
	) AS PERCENTAGE_SHARE
FROM
	PIZZAS AS P
	JOIN PIZZA_TYPES AS PT ON PT.PIZZA_TYPE_ID = P.PIZZA_TYPE_ID
	JOIN ORDER_DETAILS AS OD ON OD.PIZZA_ID = P.PIZZA_ID
GROUP BY
	PT.CATEGORY
ORDER BY
	TOTAL_ORDER DESC





"

9. Average pizzas ordered per day.

I want to see if our daily demand is consistent.
Can you group orders by date and tell me the average number
of pizzas ordered per day.


"
SELECT
	AVG(DAILY_TOTAL) AS AVG_PIZZAS_PER_DAY
FROM
	(
		SELECT
			O.ORDER_DATE,
			SUM(OD.QUANTITY) AS DAILY_TOTAL
		FROM
			ORDERS AS O
			JOIN ORDER_DETAILS AS OD ON O.ORDER_ID = OD.ORDER_ID
		GROUP BY
			O.ORDER_DATE
	) AS T;

-- using cte
WITH
	DAILY_ORDERS AS (
		SELECT
			O.ORDER_DATE,
			SUM(OD.QUANTITY) AS DAILY_TOTAL
		FROM
			ORDERS AS O
			JOIN ORDER_DETAILS AS OD ON O.ORDER_ID = OD.ORDER_ID
		GROUP BY
			O.ORDER_DATE
	)
SELECT
	ROUND(AVG(DAILY_TOTAL), 2) AS AVG_PIZZAS_PER_DAY
FROM
	DAILY_ORDERS 




"
10. Top 3 Pizzas by revenue

we need to know which pizzas are our biggest revenue drivers.
please provide the top 3 pizzas by revenue generated.

"

-- window function approach
WITH
	CTE AS (
		SELECT
			PT.NAME AS NAME,
			SUM(P.PRICE * OD.QUANTITY) AS TOTAL_PRICE,
			DENSE_RANK() OVER (
				ORDER BY
					SUM(P.PRICE * OD.QUANTITY) DESC
			) AS RNK
		FROM
			PIZZAS AS P
			JOIN PIZZA_TYPES AS PT ON PT.PIZZA_TYPE_ID = P.PIZZA_TYPE_ID
			JOIN ORDER_DETAILS AS OD ON OD.PIZZA_ID = P.PIZZA_ID
		GROUP BY
			PT.NAME
	)
SELECT
	NAME,
	TOTAL_PRICE
FROM
	CTE
WHERE
	RNK <= 3



	-- another approach


SELECT
	PT.NAME,
	SUM(P.PRICE * OD.QUANTITY) AS REVENUE
FROM
	PIZZAS P
	JOIN PIZZA_TYPES PT ON P.PIZZA_TYPE_ID = PT.PIZZA_TYPE_ID
	JOIN ORDER_DETAILS OD ON P.PIZZA_ID = OD.PIZZA_ID
GROUP BY
	PT.NAME
ORDER BY
	REVENUE DESC
LIMIT
	3;



--Advanced Analysis


"

11. Revenue contribution per pizza

for our revenue mix analysis , i need to know what percentage of 
total revenue each pizza contributes.
this will show which items carry the business.


divide revenue of each pizza by total revenue,  express in %


"


WITH REVENUE AS (
    SELECT
        PT.NAME,
        SUM(P.PRICE * OD.QUANTITY) AS TOTAL_REVENUE,
        ROUND(
            100.0 * SUM(P.PRICE * OD.QUANTITY)
            / SUM(SUM(P.PRICE * OD.QUANTITY)) OVER (),
            2
        ) AS PCT
    FROM PIZZAS P
    JOIN ORDER_DETAILS OD
        ON P.PIZZA_ID = OD.PIZZA_ID
    JOIN PIZZA_TYPES PT
        ON PT.PIZZA_TYPE_ID = P.PIZZA_TYPE_ID
    GROUP BY PT.NAME
)
SELECT
    NAME,
    TOTAL_REVENUE,
    CONCAT(PCT, '%') AS PCT_CONTRIBUTION
FROM REVENUE
ORDER BY PCT DESC;




"

12. Cumulative Revenue Over time
we want to see how our cumulative revenue has grown month by month
since launch . Can you prepare a cumulative revenue trend line?

"

SELECT
    DATE_TRUNC('month', O.ORDER_DATE) AS MONTH,
    SUM(P.PRICE * OD.QUANTITY) AS MONTHLY_REVENUE,
    SUM(SUM(P.PRICE * OD.QUANTITY)) OVER (
        ORDER BY DATE_TRUNC('month', O.ORDER_DATE)
    ) AS CUMULATIVE_REVENUE
FROM ORDERS O
JOIN ORDER_DETAILS OD
    ON O.ORDER_ID = OD.ORDER_ID
JOIN PIZZAS P
    ON P.PIZZA_ID = OD.PIZZA_ID
GROUP BY
    DATE_TRUNC('month', O.ORDER_DATE)
ORDER BY
    DATE_TRUNC('month', O.ORDER_DATE);

"

13. Top 3 Pizzas by category (Revenue-Based)
within each pizza category, which 3 pizzas bring the most revenue?
this will help us decide which pizzas to promote or expand

partition by category, calculate revenue per pizza, rank top 3.

"

WITH
	RNK_PIZZA_NAME AS (
		SELECT
			PT.NAME AS NAME,
			SUM(P.PRICE * OD.QUANTITY) AS TOTAL_REVENUE,
			RANK() OVER (
				PARTITION BY
					PT.CATEGORY
				ORDER BY
					SUM(P.PRICE * OD.QUANTITY) DESC
			) AS RNK,
			PT.CATEGORY AS CATEGORY
		FROM
			PIZZAS AS P
			JOIN ORDER_DETAILS AS OD ON P.PIZZA_ID = OD.PIZZA_ID
			JOIN PIZZA_TYPES AS PT ON PT.PIZZA_TYPE_ID = P.PIZZA_TYPE_ID
			JOIN ORDERS AS O ON O.ORDER_ID = OD.ORDER_ID
		GROUP BY
			PT.NAME,
			PT.CATEGORY
	)
SELECT
	CATEGORY,
	NAME,
	TOTAL_REVENUE
FROM
	RNK_PIZZA_NAME
WHERE
	RNK <= 3




-- Extended Business Case Studies


"
14. Top 10 Customers by Spending

who are our top 10 customers based on total spend?
we want to reward them with loyalty offers

"

WITH TOP_CUST AS (
    SELECT
        C.CUSTID,
        C.FIRST_NAME || ' ' || C.LAST_NAME AS NAME,
        SUM(P.PRICE * OD.QUANTITY) AS TOTAL_REVENUE,
        RANK() OVER (
            ORDER BY SUM(P.PRICE * OD.QUANTITY) DESC
        ) AS RNK
    FROM PIZZAS AS P
    JOIN ORDER_DETAILS AS OD
        ON P.PIZZA_ID = OD.PIZZA_ID
    JOIN ORDERS AS O
        ON O.ORDER_ID = OD.ORDER_ID
    JOIN CUSTOMERS AS C
        ON C.CUSTID = O.CUSTID
    GROUP BY
        C.CUSTID,
        C.FIRST_NAME,
        C.LAST_NAME
)
SELECT
    CUSTID,
    NAME,
    TOTAL_REVENUE
FROM TOP_CUST
WHERE RNK <= 10
ORDER BY TOTAL_REVENUE DESC;



"
15. Orders by Weekday
which days of the week are busiest for orders?
Do customers order more on weekends?
"

SELECT
	TO_CHAR(ORDER_DATE, 'day') AS WEEKDAY,
	COUNT(DISTINCT ORDER_ID) AS TOTAL_ORDERS
FROM
	ORDERS
GROUP BY
	TO_CHAR(ORDER_DATE, 'day')
ORDER BY
	TOTAL_ORDERS DESC


--Do customers order more on weekends?

SELECT
	CASE
		WHEN EXTRACT(
			DOW
			FROM
				ORDER_DATE
		) IN (0, 6) THEN 'Weekend'
		ELSE 'Weekday'
	END AS DAY_TYPE,
	COUNT(*) AS TOTAL_ORDERS
FROM
	ORDERS
GROUP BY
	DAY_TYPE;



"
16. Average Order size

what's the average number of pizzas per order?
this helps us in planning inventory and staffing

"


WITH
	CTE AS (
		SELECT
			ORDER_ID,
			SUM(QUANTITY) AS ORDER_SIZE
		FROM
			ORDER_DETAILS
		GROUP BY
			ORDER_ID
		ORDER BY
			ORDER_SIZE DESC
	)
SELECT
	(SUM(ORDER_SIZE) * 1.0 / COUNT(ORDER_SIZE)) AS AVG_ORDER
FROM
	CTE


"

17. seasonal Trends
Do we peak sales in certain month or holidays?
this will help us manage seosonal demand.

"

-- Order_Trend Month Wise.

SELECT
    TO_CHAR(ORDER_DATE,'Month') AS MONTH,
    COUNT(*) AS TOTAL_ORDERS
FROM ORDERS
GROUP BY
	EXTRACT(MONTH FROM ORDER_DATE),
    TO_CHAR(ORDER_DATE,'Month')
ORDER BY
    EXTRACT(MONTH FROM ORDER_DATE);



-- Peak Sales Month Wise.

SELECT
    TO_CHAR(O.ORDER_DATE,'Month') AS MONTH,
    ROUND(SUM(P.PRICE * OD.QUANTITY),2) AS TOTAL_SALES
FROM ORDERS O
JOIN ORDER_DETAILS OD
    ON O.ORDER_ID = OD.ORDER_ID
JOIN PIZZAS P
    ON OD.PIZZA_ID = P.PIZZA_ID
GROUP BY
    EXTRACT(MONTH FROM O.ORDER_DATE),
    TO_CHAR(O.ORDER_DATE,'Month')
ORDER BY
    EXTRACT(MONTH FROM O.ORDER_DATE);


"

18.Revenue by pizza size
what is the revenue contribution of each pizza
size( S, M, L, XL, XXL )?

"

SELECT
	P.SIZE,
	SUM(P.PRICE * OD.QUANTITY) AS TOTAL_REVENUE
FROM
	PIZZAS AS P
	JOIN ORDER_DETAILS AS OD ON P.PIZZA_ID = OD.PIZZA_ID
	JOIN PIZZA_TYPES AS PT ON PT.PIZZA_TYPE_ID = P.PIZZA_TYPE_ID
GROUP BY
	P.SIZE
ORDER BY
	TOTAL_REVENUE DESC


"

19. Customer Segmentation
Do our high-value customers prefer premium pizzas or
regular pizzas? we want to personalize marketing.

"

-- Customer Segmentation

WITH
	CUST_SPEND AS (
		SELECT
			C.CUSTID AS CUSTID,
			SUM(P.PRICE * OD.QUANTITY) AS TOTAL_SPEND
		FROM
			PIZZAS AS P
			JOIN ORDER_DETAILS AS OD ON P.PIZZA_ID = OD.PIZZA_ID
			--JOIN PIZZA_TYPES AS PT ON PT.PIZZA_TYPE_ID = P.PIZZA_TYPE_ID
			JOIN ORDERS AS O ON O.ORDER_ID = OD.ORDER_ID
			JOIN CUSTOMERS AS C ON C.CUSTID = O.CUSTID
		GROUP BY
			C.CUSTID
	)
SELECT
	CASE
		WHEN TOTAL_SPEND > 80000 THEN 'High_value'
		ELSE 'Regular'
	END AS SEGMENT,
	COUNT(*) AS CUSTOMER_COUNT
FROM
	CUST_SPEND
GROUP BY
	SEGMENT


-- Premium & Regular Pizzas

WITH CUSTOMER_SPENDING AS (
    SELECT
        O.CUSTID,
        SUM(P.PRICE * OD.QUANTITY) AS TOTAL_SPEND
    FROM ORDERS O
    JOIN ORDER_DETAILS OD
        ON O.ORDER_ID = OD.ORDER_ID
    JOIN PIZZAS P
        ON P.PIZZA_ID = OD.PIZZA_ID
    GROUP BY O.CUSTID
)

SELECT
    CASE
        WHEN CS.TOTAL_SPEND > 80000 THEN 'High Value'
        ELSE 'Regular'
    END AS CUSTOMER_SEGMENT,

    CASE
        WHEN P.PRICE >= 20 THEN 'Premium'
        ELSE 'Regular'
    END AS PIZZA_TYPE,

    SUM(OD.QUANTITY) AS TOTAL_PIZZAS

FROM CUSTOMER_SPENDING CS
JOIN ORDERS O
    ON CS.CUSTID = O.CUSTID
JOIN ORDER_DETAILS OD
    ON O.ORDER_ID = OD.ORDER_ID
JOIN PIZZAS P
    ON P.PIZZA_ID = OD.PIZZA_ID
GROUP BY
    CUSTOMER_SEGMENT,
    PIZZA_TYPE;



"
20. Repeat Customer Rate?
we want to measure customer loyalty. can you calculate the percentage
of repeat customers (customers who placed more than one order)
versus one - time buyers? this will help us design retention campaigns
"


-- Repeate Customer Rate


WITH CUSTOMER_ORDERS AS (
    SELECT
        CUSTID,
        COUNT(DISTINCT ORDER_ID) AS TOTAL_ORDERS
    FROM ORDERS
    GROUP BY CUSTID
)
SELECT
    ROUND(
        100.0 * SUM(CASE WHEN TOTAL_ORDERS > 1 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS REPEAT_CUSTOMER_RATE

FROM CUSTOMER_ORDERS;



-- One time Buyers


WITH CUSTOMER_ORDERS AS (
    SELECT
        CUSTID,
        COUNT(DISTINCT ORDER_ID) AS TOTAL_ORDERS
    FROM ORDERS
    GROUP BY CUSTID
)
SELECT
    ROUND(
        100.0 * SUM(CASE WHEN TOTAL_ORDERS = 1 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS ONE_TIME_BUYER_RATE
FROM CUSTOMER_ORDERS;




" 
21.Monthly Customer Growth

"



WITH MONTHLY_CUSTOMERS AS (
    SELECT
        DATE_TRUNC('month', FIRST_ORDER_DATE) AS MONTH,
        COUNT(*) AS NEW_CUSTOMERS
    FROM (
        SELECT
            CUSTID,
            MIN(ORDER_DATE) AS FIRST_ORDER_DATE
        FROM ORDERS
        GROUP BY CUSTID
    ) T
    GROUP BY DATE_TRUNC('month', FIRST_ORDER_DATE)
)
SELECT
    MONTH,
    NEW_CUSTOMERS,
    LAG(NEW_CUSTOMERS) OVER (ORDER BY MONTH) AS PREVIOUS_MONTH,
    ROUND(
        100.0 * (
            NEW_CUSTOMERS -
            LAG(NEW_CUSTOMERS) OVER (ORDER BY MONTH)
        ) /
        LAG(NEW_CUSTOMERS) OVER (ORDER BY MONTH),
        2
    ) AS GROWTH_PERCENT
FROM MONTHLY_CUSTOMERS
ORDER BY MONTH;

