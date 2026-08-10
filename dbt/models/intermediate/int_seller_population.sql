{{ config(materialized='view') }}

SELECT seller_id
FROM {{ source('silver', 'olist_sellers') }}
UNION
SELECT seller_id
FROM {{ source('silver', 'olist_closed_deals') }}