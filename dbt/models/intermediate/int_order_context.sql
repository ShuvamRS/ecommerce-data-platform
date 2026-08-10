{{ config(materialized='view') }}

SELECT
    O.order_id,
    D.customer_key,
    L.location_key AS customer_location_key
FROM {{ source('silver', 'olist_orders') }} AS O
    INNER JOIN {{ ref('olist_customers_normalized') }} AS C
        ON O.customer_id = C.customer_id
    INNER JOIN {{ ref('dim_customer') }} AS D
        ON C.customer_unique_id = D.customer_unique_id
    INNER JOIN {{ ref('dim_location') }} AS L
        ON C.customer_zip_code_prefix = L.zip_code_prefix
        AND C.normalized_city = L.city
        AND C.normalized_state = L.state