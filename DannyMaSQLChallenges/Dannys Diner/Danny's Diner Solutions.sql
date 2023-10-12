/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT 
    s.customer_id, SUM(m.price) AS Total_price
FROM
    dannys_diner.sales s
        JOIN
    dannys_diner.menu m ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY Total_price;  
-- 2. How many days has each customer visited the restaurant?
SELECT 
    customer_id,
    COUNT(DISTINCT order_date) AS number_of_times_visited
FROM
    dannys_diner.sales
GROUP BY customer_id;  
-- 3. What was the first item from the menu purchased by each customer?
WITH first_order AS(
SELECT s.customer_id,m.product_name, s.order_date,
DENSE_RANK() OVER ( PARTITION BY s.customer_id
ORDER BY s.order_date) AS orders_rank FROM
dannys_diner.sales s JOIN dannys_diner.menu m ON s.product_id = m.product_id GROUP BY s.customer_id, s.order_date, m.product_name)
SELECT customer_id,product_name as first_ordered_item FROM first_order WHERE orders_rank =1; 
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
    m.product_name AS most_purchased_item,
    COUNT(s.product_id) AS number_of_times_purchased
FROM
    dannys_diner.sales s
        JOIN
    dannys_diner.menu m ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY number_of_times_purchased DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH most_popular_item AS(
SELECT s.customer_id,m.product_name,COUNT(s.product_id) as number_of_times_purchased, DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS number_of_times_purchased_rank FROM dannys_diner.sales s JOIN dannys_diner.menu m ON s.product_id = m.product_id GROUP BY m.product_name, s.customer_id ORDER BY number_of_times_purchased DESC
)
SELECT customer_id,product_name,number_of_times_purchased FROM most_popular_item WHERE number_of_times_purchased_rank=1;


-- 6. Which item was purchased first by the customer after they became a member?
WITH first_purchased_item AS( 
SELECT m.product_name,mem.customer_id,s.order_date,
DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS order_date_rank from dannys_diner.menu m JOIN dannys_diner.sales s ON m.product_id = s.product_id JOIN dannys_diner.members mem ON s.customer_id = mem.customer_id WHERE s.order_date > mem.join_date)
SELECT customer_id,product_name FROM first_purchased_item WHERE order_date_rank=1; 

-- 7. Which item was purchased just before the customer became a member?
 WITH CTE1 AS (
SELECT m.product_name,mem.customer_id,s.order_date,
DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS order_date_rank from dannys_diner.menu m JOIN dannys_diner.sales s ON m.product_id = s.product_id JOIN dannys_diner.members mem ON s.customer_id = mem.customer_id WHERE s.order_date < mem.join_date)
SELECT product_name, customer_id FROM CTE1 where order_date_rank = 1; 

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT 
    s.customer_id,
    COUNT(s.product_id) AS Total_items,
    SUM(price) AS Amount_Spent
FROM
    dannys_diner.menu m
        JOIN
    dannys_diner.sales s ON m.product_id = s.product_id
        JOIN
    dannys_diner.members mem ON s.customer_id = mem.customer_id
WHERE
    s.order_date < mem.join_date
GROUP BY s.customer_id;
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT 
    s.customer_id,
    SUM(CASE
        WHEN m.product_name = 'sushi' THEN m.price * 20
        ELSE price * 10
    END) AS points
FROM
    dannys_diner.menu m
        JOIN
    dannys_diner.sales s ON m.product_id = s.product_id
GROUP BY s.customer_id; 

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH offer_dates AS (
SELECT customer_id,join_date,adddate(join_date,7) AS offer_end_date FROM dannys_diner.members)
SELECT s.customer_id,
SUM(CASE
WHEN (order_date BETWEEN mem.join_date AND offer_end_date) OR m.product_name='sushi' THEN m.price * 10 * 2
ELSE m.price * 10
END) AS points_accumulated
FROM dannys_diner.menu m JOIN dannys_diner.sales s ON m.product_id = s.product_id JOIN dannys_diner.members mem ON  s.customer_id = mem.customer_id JOIN offer_dates o ON o.customer_id = s.customer_id
WHERE s.order_date <=CAST('2021-01-31' AS date) GROUP BY s.customer_id ORDER BY points_accumulated DESC; 


-- BONUS QUESTION 
-- JOIN ALL TABLES
SELECT s.customer_id,s.order_date,m.product_name,m.price,
CASE 
WHEN mem.join_date <= s.order_date THEN 'Y'
ELSE 'N'
END AS mem
FROM dannys_diner.menu m FULL JOIN sales s ON m.product_id = s.product_id JOIN members mem ON  s.customer_id = mem.customer_id
ORDER BY s.customer_id, s.order_date ASC; 

-- Bonus Question 2
WITH cte1 AS(
SELECT s.customer_id,s.order_date,m.product_name,m.price,
CASE 
	WHEN mem.join_date <= s.order_date THEN 'Y'
	WHEN mem.join_date > s.order_date THEN 'N'
	ELSE 'N'
END AS member_stat
FROM 
menu m LEFT OUTER JOIN sales s ON m.product_id = s.product_id LEFT OUTER JOIN members mem ON  s.customer_id = mem.customer_id
) 
SELECT * , 
CASE 
	WHEN member_stat = 'N' then NULL
	ELSE RANK() OVER (PARTITION BY customer_id, member_stat ORDER BY order_date)
END AS ranking FROM cte1;
