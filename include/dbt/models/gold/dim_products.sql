{{ config(materialized='view') }}

WITH product AS (
    SELECT *
    FROM {{ ref('crm_prd_info') }}
),
category AS (
    SELECT *
    FROM {{ ref('erp_px_cat_g1v2') }}
)

SELECT
    ROW_NUMBER() OVER (ORDER BY product.prd_start_dt, product.prd_key) AS product_key, -- Surrogate key
    product.prd_id         AS product_id,
    product.prd_key        AS product_number,
    product.prd_nm         AS product_name,
    product.cat_id         AS category_id,
    category.cat           AS category,
    category.subcat        AS subcategory,
    category.maintenance   AS maintenance,
    product.prd_cost       AS cost,
    product.prd_line       AS product_line,
    product.prd_start_dt   AS start_date
FROM product
LEFT JOIN category
    ON product.cat_id = category.id
WHERE product.prd_end_dt IS NULL -- Filter out all historical data
