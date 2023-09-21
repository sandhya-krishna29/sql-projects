#Request 1
SELECT DISTINCT
    (market)
FROM
    dim_customer
WHERE
    customer = 'Atliq Exclusive'
        AND region = 'APAC'
ORDER BY market;

#Request 2
WITH unique2020 AS
(SELECT COUNT(DISTINCT(product_code)) as unique_products_2020 FROM fact_sales_monthly WHERE fiscal_year = 2020),
unique2021 AS 
(SELECT COUNT(DISTINCT(product_code)) as unique_products_2021 FROM fact_sales_monthly WHERE fiscal_year = 2021)
SELECT unique_products_2020,unique_products_2021,CONCAT(ROUND((((unique_products_2021 - unique_products_2020)/unique_products_2020)*100),2),'%') AS percentage_chg from unique2020 JOIN unique2021;

#Request 3
SELECT 
    segment, COUNT(DISTINCT (product_code)) AS product_count
FROM
    dim_product
GROUP BY segment
ORDER BY product_count DESC;


#Request 4
WITH product_count_2020 AS (
SELECT 
    dm.segment,
    COUNT(DISTINCT (dm.product_code)) AS product_count_2020
FROM
    dim_product dm
        JOIN
    fact_sales_monthly AS fsm ON dm.product_code = fsm.product_code
WHERE
    fiscal_year = 2020
GROUP BY segment
), product_count_2021 AS (
SELECT 
    dm.segment,
    COUNT(DISTINCT (dm.product_code)) AS product_count_2021
FROM
    dim_product dm
        JOIN
    fact_sales_monthly AS fsm ON dm.product_code = fsm.product_code
WHERE
    fiscal_year = 2021
GROUP BY segment
)
SELECT 
    product_count_2020.segment,
    product_count_2020,
    product_count_2021,
    product_count_2021 - product_count_2020 AS difference
FROM
    product_count_2020
        JOIN
    product_count_2021 ON product_count_2020.segment = product_count_2021.segment
ORDER BY difference DESC;

#Request 5
SELECT 
    fmc.product_code, dp.product, fmc.manufacturing_cost
FROM
    fact_manufacturing_cost fmc
        JOIN
    dim_product dp ON dp.product_code = fmc.product_code
WHERE
    fmc.manufacturing_cost = (SELECT 
            MAX(manufacturing_cost)
        FROM
            fact_manufacturing_cost)
        OR fmc.manufacturing_cost = (SELECT 
            MIN(manufacturing_cost)
        FROM
            fact_manufacturing_cost);
            
#Request 6
SELECT 
    dc.customer_code,
    customer,
    ROUND(AVG(fpid.pre_invoice_discount_pct), 2) AS pre_invoice_discount_pct
FROM
    dim_customer dc
        JOIN
    fact_pre_invoice_deductions fpid ON dc.customer_code = fpid.customer_code
WHERE
    dc.market = 'India'
        AND fpid.fiscal_year = 2021
GROUP BY dc.customer
ORDER BY fpid.pre_invoice_discount_pct DESC
LIMIT 5;


# Request 7 

SELECT 
    EXTRACT(YEAR FROM fsm.date) AS Year,
    EXTRACT(MONTH FROM fsm.date) AS Month,
    SUM(fsm.sold_quantity * fgp.gross_price) AS Gross_Sales_Amount
FROM
    fact_sales_monthly fsm
        JOIN
    fact_gross_price fgp ON fsm.product_code = fgp.product_code
        JOIN
    dim_customer dc ON fsm.customer_code = dc.customer_code
WHERE
    dc.customer = 'Atliq Exclusive'
GROUP BY month , year
ORDER BY Gross_Sales_Amount DESC;

#Request 8 
SELECT SUM(sold_quantity) as total_sold_quantity,
CASE
    WHEN month(date) IN (9,10,11) THEN 'Quarter 1'
    WHEN month(date) IN (12,1,2) THEN 'Quarter 2'
    WHEN month(date) IN (3,4,5) THEN 'Quarter 3'
    ELSE 'Quarter 4'
END AS Quarter
FROM fact_sales_monthly WHERE fiscal_year = 2020 GROUP BY Quarter ORDER BY total_sold_quantity DESC;


#Request 9
WITH sum_gross_sales_mln AS 
(
SELECT ROUND((SUM(fsm.sold_quantity*fgp.gross_price)/1000000),2) sum_gross_sales_mln FROM fact_sales_monthly fsm JOIN fact_gross_price fgp ON fsm.product_code=fgp.product_code JOIN dim_customer dc ON fsm.customer_code = dc.customer_code WHERE fsm.fiscal_year=2021
),
select_others AS
(
SELECT dc.channel,ROUND((SUM(fsm.sold_quantity*fgp.gross_price)/1000000),2) gross_sales_mln FROM fact_sales_monthly fsm JOIN fact_gross_price fgp ON fsm.product_code=fgp.product_code JOIN dim_customer dc ON fsm.customer_code = dc.customer_code WHERE fsm.fiscal_year=2021 GROUP BY dc.channel ORDER BY gross_sales_mln DESC
)
SELECT channel, gross_sales_mln, CONCAT(ROUND(((gross_sales_mln/sum_gross_sales_mln)*100),2),"%") percentage FROM sum_gross_sales_mln,select_others;



#Request 10
WITH cte1 AS
(				SELECT 
				fsm.product_code,
				dp.product,
				dp.division,
				SUM(fsm.sold_quantity) total_sold_quantity, 
				RANK() OVER (partition by dp.DIVISION ORDER BY SUM(fsm.sold_quantity) DESC) rank_order 
				FROM fact_sales_monthly fsm 
				JOIN dim_product dp ON 
				fsm.product_code=dp.product_code 
				WHERE fsm.fiscal_year = 2021 
				GROUP BY dp.product
				ORDER BY dp.division ASC, total_sold_quantity DESC
)
SELECT * FROM cte1 WHERE rank_order <=3;

