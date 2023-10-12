USE pizza_runner;

SELECT * FROM customer_orders;

SELECT * FROM pizza_names;

SELECT * FROM runner_orders;

DROP TABLE IF EXISTS customer_orders_temp;
CREATE TEMPORARY TABLE customer_orders_temp
SELECT order_id,
  customer_id,
  pizza_id,
  CASE 
	WHEN exclusions = 'null' OR exclusions = ''  THEN NULL
	ELSE exclusions
  END as exclusions,
  CASE WHEN extras='' OR extras = 'null' THEN null
  ELSE extras
  END as extras,
  order_time 
  FROM customer_orders;
  
DROP TABLE IF EXISTS runner_orders_temp;

CREATE TEMPORARY TABLE runner_orders_temp
SELECT order_id, runner_id, 
CASE WHEN pickup_time ='' OR pickup_time = 'null' THEN null
ELSE pickup_time
END AS pickuptime, 
CASE 
WHEN distance='' OR distance = 'null' THEN null
WHEN distance LIKE '%km' THEN REPLACE(distance,'km','')
ELSE distance 
END AS distance_in_km, 
CASE 
WHEN duration='' OR duration ='null' THEN null
WHEN duration LIKE '%min' THEN REPLACE(duration,'min','')
WHEN duration LIKE '%mins' THEN REPLACE(duration,'mins','')
WHEN duration LIKE '%minute' THEN REPLACE(duration,'minute','') 
WHEN duration LIKE '%minutes' THEN REPLACE(duration,'minutes','')
ELSE duration
END as duration_in_min, 
CASE WHEN cancellation ='' OR cancellation = 'null' THEN null
ELSE cancellation
END as cancellation FROM runner_orders;

SELECT * FROM customer_orders_temp;

SELECT * FROM runner_orders_temp;


  