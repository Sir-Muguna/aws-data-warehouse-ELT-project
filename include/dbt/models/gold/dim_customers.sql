{{ config(materialized='view') }}

WITH crm AS (
    SELECT *
    FROM {{ ref('crm_cust_info') }}
),
erp AS (
    SELECT *
    FROM {{ ref('erp_cust_az12') }}
),
loc AS (
    SELECT *
    FROM {{ ref('erp_loc_a101') }}
)


SELECT
    ROW_NUMBER() OVER (ORDER BY crm.cst_id) AS customer_key, -- Surrogate key
    crm.cst_id                          AS customer_id,
    crm.cst_key                         AS customer_number,
    crm.cst_firstname                   AS first_name,
    crm.cst_lAStname                    AS last_name,
    loc.cntry                           AS country,
    crm.cst_marital_status              AS marital_status,
    CASE 
        WHEN crm.cst_gndr != 'n/a' THEN crm.cst_gndr -- CRM is the primary source for gender
        ELSE COALESCE(erp.gen, 'n/a') -- Fallback to ERP data
    END                                 AS gender,
    erp.bdate                           AS birthdate,
    crm.cst_create_date                 AS create_date
FROM crm
LEFT JOIN erp
    ON crm.cst_key = erp.cid
LEFT JOIN loc
    ON crm.cst_key = loc.cid
