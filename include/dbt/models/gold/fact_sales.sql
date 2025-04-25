{{ config(materialized='view') }}

WITH sales AS (
    SELECT *
    FROM {{ ref('crm_sales_details') }}
),
products AS (
    SELECT *
    FROM {{ ref('dim_products') }}
),
customers AS (
    SELECT *
    FROM {{ ref('dim_customers') }}
)

SELECT
    sales.sls_ord_num     AS order_number,
    products.product_key  AS product_key,
    customers.customer_key AS customer_key,
    sales.sls_order_dt    AS order_date,
    sales.sls_ship_dt     AS shipping_date,
    sales.sls_due_dt      AS due_date,
    sales.sls_sales       AS sales_amount,
    sales.sls_quantity    AS quantity,
    sales.sls_price       AS price
FROM sales
LEFT JOIN products
    ON sales.sls_prd_key = products.product_number
LEFT JOIN customers
    ON sales.sls_cust_id = customers.customer_id
