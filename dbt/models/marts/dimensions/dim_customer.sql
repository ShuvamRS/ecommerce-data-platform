{{ config(materialized='table') }}

SELECT DISTINCT
    CONCAT(
        'customer|',
        customer_unique_id
    ) AS customer_key,
    customer_unique_id
FROM {{ source('silver', 'olist_customers') }}