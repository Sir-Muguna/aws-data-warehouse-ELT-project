{{
  config(
    materialized='table',
    tags=['erp']
  )
}}

SELECT
  id,
  cat,
  subcat,
  maintenance
FROM {{ source('bronze', 'erp_px_cat_g1v2') }}