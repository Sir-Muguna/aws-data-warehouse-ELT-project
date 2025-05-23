{{ config(
  materialized='table',
  tags=['crm']
) }}

SELECT 
  prd_id,
  REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id, -- Extract category ID  
  SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key, -- Extract product key
  TRIM(prd_nm) AS prd_nm,  
  CAST(COALESCE(prd_cost, 0) AS DECIMAL(18,2)) AS prd_cost, 
  CASE 
    WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
    WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
    WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
    WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
    ELSE 'n/a'  
  END AS prd_line, -- Map product line codes to descriptive values
  CAST(prd_start_dt AS DATE) AS prd_start_dt,
  CAST(
          LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 
          AS DATE
        ) AS prd_end_dt -- Calculate end date as one day before the next start date
FROM {{ source('bronze', 'crm_prd_info') }}
