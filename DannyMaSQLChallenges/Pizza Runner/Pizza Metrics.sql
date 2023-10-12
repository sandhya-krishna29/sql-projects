USE pizza_runner;
SELECT 
    *
FROM
    customer_orders_temp;
SELECT 
    *
FROM
    runner_orders_temp;
SELECT 
    *
FROM
    pizza_names;
SELECT 
    *
FROM
    pizza_recipes;
SELECT 
    *
FROM
    pizza_toppings;
SELECT 
    *
FROM
    runners;

-- PIZZA METRICS
-- How many pizzas were ordered?
SELECT 
    COUNT(*) AS number_of_pizzas_ordered
FROM
    customer_orders_temp;

-- How many unique customer orders were made?
SELECT 
    COUNT(DISTINCT order_id) AS unique_pizza_orders
FROM
    customer_orders_temp;

-- How many successful orders were delivered by each runner?
SELECT 
    runner_id, COUNT(order_id) AS orders
FROM
    runner_orders_temp
WHERE
    cancellation IS NULL
GROUP BY runner_id;

-- How many of each type of pizza was delivered?
SELECT 
    pn.pizza_id, pn.pizza_name, COUNT(co.order_id)
FROM
    customer_orders_temp co
        JOIN
    pizza_names pn ON co.pizza_id = pn.pizza_id
GROUP BY pn.pizza_id , pn.pizza_name;

-- How many Vegetarian and Meatlovers were ordered by each customer?
SELECT 
    co.customer_id, pn.pizza_name, COUNT(co.order_id)
FROM
    customer_orders_temp co
        JOIN
    pizza_names pn ON co.pizza_id = pn.pizza_id
GROUP BY co.customer_id , pn.pizza_name;

-- What was the maximum number of pizzas delivered in a single order?
WITH cte1 AS
(SELECT COUNT(pizza_id) as number_of_orders,order_id FROM customer_orders_temp GROUP BY order_id)
SELECT max(number_of_orders) as max_orders FROM cte1;

-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT 
    customer_id,
    SUM(CASE
        WHEN
            (exclusions IS NOT NULL
                OR extras IS NOT NULL)
        THEN
            1
        ELSE 0
    END) AS pizzas_with_atleast_one_change,
    SUM(CASE
        WHEN (exclusions IS NULL AND extras IS NULL) THEN 1
        ELSE 0
    END) AS pizzas_with_no_change
FROM
    customer_orders_temp
GROUP BY customer_id;

-- How many pizzas were delivered that had both exclusions and extras?
SELECT 
    COUNT(*) AS pizzas_with_both_exclusions_and_extras
FROM
    customer_orders_temp
WHERE
    exclusions IS NOT NULL
        AND extras IS NOT NULL;

-- What was the total volume of pizzas ordered for each hour of the day?
SELECT 
    EXTRACT(HOUR FROM order_time) AS Hour_of_the_day,
    COUNT(order_id) AS pizza_counts,
    CONCAT(ROUND(COUNT(order_id)/SUM(COUNT(order_id)) OVER() * 100,2),"%") AS volume_of_pizzas_ordered
FROM
    customer_orders_temp
GROUP BY 1
ORDER BY 1;

-- What was the volume of orders for each day of the week?
SELECT 
  dayname(order_time) AS Day_of_the_week, 
  COUNT(order_id), 
  CONCAT(
    ROUND(
      COUNT(order_id)/ SUM(
        COUNT(order_id)
      ) OVER() * 100, 
      2
    ), 
    "%"
  ) AS volume_of_pizzas_ordered 
FROM 
  customer_orders_temp 
GROUP BY 
  1, 
  dayofweek(order_time) 
ORDER BY 
  dayofweek(order_time);