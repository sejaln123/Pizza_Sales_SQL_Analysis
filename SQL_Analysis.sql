CREATE DATABASE PIZZAHUT;
USE PIZZAHUT;

CREATE TABLE ORDERS(
ORDER_ID INT NOT NULL,
ORDER_DATE DATE NOT NULL,
ORDER_TIME TIME NOT NULL,
PRIMARY KEY(ORDER_ID));

CREATE TABLE ORDER_DETAILS(
ORDER_DETAILS_ID INT NOT NULL,
ORDER_ID INT NOT NULL,
PIZZA_ID VARCHAR(50),
QUANTITY INT NOT NULL,
PRIMARY KEY(ORDER_DETAILS_ID));

-- BASIC QUERIES-- 
-- Count how many pizzas were sold in total.
SELECT SUM(QUANTITY) AS TOTAL_PIZZAS_SOLD FROM ORDER_DETAILS ;

-- List all pizzas that were never ordered.
SELECT OD.PIZZA_ID,P.PIZZA_TYPE_ID 
FROM ORDER_DETAILS AS OD JOIN PIZZAS AS P
WHERE OD.PIZZA_ID = NULL;

-- Find the cheapest pizza.
SELECT PIZZA_ID, PRICE FROM PIZZAS 
ORDER BY PRICE LIMIT 1;

-- Retrieving the total number of orders placed.--
SELECT COUNT(ORDER_ID) FROM ORDERS;

-- Calculate the total revenue generated from pizza sales-- 
SELECT ROUND(SUM(O.QUANTITY * P.PRICE),2) AS TOTAL_REVENUE 
FROM 
ORDER_DETAILS AS O JOIN PIZZAS AS P
ON P.PIZZA_ID = O.PIZZA_ID;

-- Identify the highest-priced pizza.--
SELECT PIZZA_TYPES.NAME, PIZZAS.PRICE
FROM PIZZA_TYPES JOIN PIZZAS
ORDER BY PIZZAS.PRICE DESC LIMIT 1 ;

-- Identify the most common pizza size ordered.
SELECT QUANTITY, COUNT(ORDER_DETAILS_ID) 
FROM ORDER_DETAILS 
GROUP BY QUANTITY;

SELECT P.SIZE, COUNT(O.ORDER_DETAILS_ID) AS ORDER_COUNT
FROM PIZZAS AS P JOIN ORDER_DETAILS AS O
GROUP BY P.SIZE
ORDER BY ORDER_COUNT DESC;

-- List the top 5 most ordered pizza types along with their quantities.
SELECT SUM(O.QUANTITY) AS SUM_QUANTITY, PT.NAME
FROM PIZZA_TYPES AS PT JOIN PIZZAS AS P 
ON PT.PIZZA_TYPE_ID = P.PIZZA_TYPE_ID
JOIN ORDER_DETAILS AS O
ON O.PIZZA_ID = P.PIZZA_ID
GROUP BY PT.NAME
ORDER BY SUM_QUANTITY DESC LIMIT 5;




-- Intermediate queries:
-- Join the necessary tables to find the total quantity of each pizza category ordered.
SELECT SUM(O.QUANTITY), PT.CATEGORY 
FROM 
PIZZA_TYPES AS PT JOIN PIZZAS AS P
ON PT.PIZZA_TYPE_ID = P.PIZZA_TYPE_ID
JOIN 
ORDER_DETAILS AS O 
ON O.PIZZA_ID = P.PIZZA_ID
GROUP BY PT.CATEGORY;

-- Determine the distribution of orders by hour of the day.
SELECT COUNT(OD.ORDER_ID) AS ORDER_COUNT_PER_TIME, HOUR(O.ORDER_TIME)
FROM ORDER_DETAILS AS OD JOIN ORDERS AS O
ON O.ORDER_ID = OD.ORDER_ID
GROUP BY HOUR(O.ORDER_TIME);

-- Join relevant tables to find the category-wise distribution of pizzas.
SELECT COUNT(NAME), CATEGORY FROM PIZZA_TYPES
GROUP BY CATEGORY;

-- Group the orders by date and calculate the average number of pizzas ordered per day.
SELECT AVG(SUM_PER_DAY) FROM  
(SELECT SUM(OD.QUANTITY) AS SUM_PER_DAY, O.ORDER_DATE 
FROM ORDERS AS O JOIN ORDER_DETAILS AS OD
ON O.ORDER_ID = OD.ORDER_ID
GROUP BY ORDER_DATE) AS DATA;

-- Determine the top 3 most ordered pizza types based on revenue.
SELECT PT.NAME, SUM(P.PRICE*OD.QUANTITY) AS REVENUE
FROM PIZZAS AS P JOIN ORDER_DETAILS AS OD ON P.PIZZA_ID = OD.PIZZA_ID 
JOIN PIZZA_TYPES AS PT ON P.PIZZA_TYPE_ID = PT.PIZZA_TYPE_ID
GROUP BY PT.NAME 
ORDER BY REVENUE DESC LIMIT 3;

-- Find the average order value (AOV).
SELECT (SUM(P.PRICE * OD.QUANTITY) / COUNT(DISTINCT OD.ORDER_ID)) AS AOV
FROM ORDER_DETAILS AS OD JOIN PIZZAS AS P 
ON OD.PIZZA_ID = P.PIZZA_ID;

-- Identify the peak ordering days (weekday analysis).
SELECT COUNT(OD.ORDER_ID) AS TOTAL_ORDERS, DAYNAME(O.ORDER_DATE) AS WEEKDAY
FROM ORDER_DETAILS AS OD JOIN ORDERS AS O
ON O.ORDER_ID = OD.ORDER_ID
GROUP BY DAYNAME(O.ORDER_DATE)
ORDER BY TOTAL_ORDERS DESC;

-- Find which pizza size generates the highest revenue.
SELECT P.SIZE, SUM(P.PRICE*OD.QUANTITY) AS REVENUE
FROM PIZZAS AS P JOIN ORDER_DETAILS AS OD ON P.PIZZA_ID = OD.PIZZA_ID 
JOIN PIZZA_TYPES AS PT ON P.PIZZA_TYPE_ID = PT.PIZZA_TYPE_ID
GROUP BY P.SIZE
ORDER BY REVENUE DESC;




-- Advanced:
-- Calculate the percentage contribution of each pizza type to total revenue.
SELECT PT.CATEGORY, ROUND(SUM(P.PRICE*OD.QUANTITY)  / (SELECT ROUND(SUM(OD.QUANTITY * P.PRICE),2) AS TOTAL_SALES 
FROM ORDER_DETAILS AS OD JOIN PIZZAS AS P
ON OD.PIZZA_ID = P.PIZZA_ID)*100,2) AS REVENUE
FROM PIZZAS AS P JOIN ORDER_DETAILS AS OD ON P.PIZZA_ID = OD.PIZZA_ID 
JOIN PIZZA_TYPES AS PT ON P.PIZZA_TYPE_ID = PT.PIZZA_TYPE_ID
GROUP BY PT.CATEGORY 
ORDER BY REVENUE DESC;

-- Analyze the cumulative revenue generated over time.
SELECT ORDER_DATE, SUM(REVENUE) OVER (ORDER BY ORDER_DATE) AS CUM_REVENUE
FROM 
(SELECT O.ORDER_DATE, SUM(OD.QUANTITY * P.PRICE) AS REVENUE
FROM ORDERS AS O JOIN ORDER_DETAILS AS OD ON O.ORDER_ID = OD.ORDER_ID
JOIN PIZZAS AS P ON P.PIZZA_ID = OD.PIZZA_ID
GROUP BY O.ORDER_DATE) AS SALES;

-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.
SELECT CATEGORY,NAME, REVENUE FROM
(SELECT CATEGORY,NAME,REVENUE,
RANK() OVER(PARTITION BY CATEGORY ORDER BY REVENUE DESC) AS RN
FROM
(SELECT PT.NAME,PT.CATEGORY, SUM(P.PRICE*OD.QUANTITY) AS REVENUE
FROM PIZZAS AS P JOIN ORDER_DETAILS AS OD ON P.PIZZA_ID = OD.PIZZA_ID 
JOIN PIZZA_TYPES AS PT ON P.PIZZA_TYPE_ID = PT.PIZZA_TYPE_ID
GROUP BY PT.NAME, PT.CATEGORY) AS A) AS B
WHERE RN <=3;

-- Identify revenue trends by week or month.
SELECT MONTH(o.order_date) AS month, SUM(p.price * od.quantity) AS revenue
FROM orders o JOIN order_details od ON o.order_id = od.order_id
JOIN pizzas p ON p.pizza_id = od.pizza_id
GROUP BY MONTH(o.order_date)
ORDER BY month;

-- Calculate moving average of weekly revenue.
WITH weekly_revenue AS (SELECT YEAR(o.order_date) AS yr,
WEEK(o.order_date) AS wk,
DATE_ADD(MIN(o.order_date), INTERVAL -((DAYOFWEEK(MIN(o.order_date))-1)) DAY) AS week_start,
SUM(p.price * od.quantity) AS revenue
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN pizzas p ON p.pizza_id = od.pizza_id
GROUP BY YEAR(o.order_date), WEEK(o.order_date)
)
SELECT yr,wk,week_start,revenue,ROUND(AVG(revenue) OVER (ORDER BY yr, wk
ROWS BETWEEN 2 PRECEDING AND CURRENT ROW ), 2) AS moving_avg_3wk
FROM weekly_revenue
ORDER BY yr, wk;

-- A/B comparison between pizza sizes/prices
SELECT
  p.size,
  COUNT(DISTINCT od.order_id) AS orders_count,
  SUM(od.quantity) AS total_quantity,
  ROUND(AVG(p.price),2) AS avg_price,
  ROUND(SUM(p.price * od.quantity),2) AS total_revenue
FROM pizzas p
JOIN order_details od ON p.pizza_id = od.pizza_id
GROUP BY p.size
ORDER BY total_revenue DESC;

-- Basket analysis 
SELECT
  LEAST(p1.pizza_id, p2.pizza_id) AS pizza_a,
  GREATEST(p1.pizza_id, p2.pizza_id) AS pizza_b,
  COUNT(DISTINCT p1.order_id) AS times_ordered_together
FROM order_details p1
JOIN order_details p2
  ON p1.order_id = p2.order_id
  AND p1.pizza_id < p2.pizza_id       
GROUP BY pizza_a, pizza_b
ORDER BY times_ordered_together DESC
LIMIT 50;











