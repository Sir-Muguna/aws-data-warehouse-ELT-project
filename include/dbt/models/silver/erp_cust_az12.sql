{{
  config(
    materialized='table',
    tags=['erp']
  )
}}

SELECT
  CASE
    WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) -- Remove 'NAS' prefix if present
    ELSE cid
  END AS cid,
  
  CASE 
    WHEN bdate > CURRENT_DATE THEN NULL
    WHEN bdate < '1900-01-01' THEN NULL  
    ELSE bdate
  END AS bdate,  -- Set future birthdates to NULL
  
  CASE 
    WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
    WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'  
    ELSE 'n/a' 
  END AS gen  -- Normalize gender values and handle unknown cases
FROM {{ source('bronze', 'erp_cust_az12') }}