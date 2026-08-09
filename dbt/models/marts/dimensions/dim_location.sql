{{ config(materialized='table') }}

WITH T AS (
    SELECT
        customer_zip_code_prefix AS zip_code_prefix,
        normalized_city,
        normalized_state
    FROM {{ ref('olist_customers_normalized') }}
    UNION
    SELECT
        seller_zip_code_prefix AS zip_code_prefix,
        normalized_city,
        normalized_state
    FROM {{ ref('olist_sellers_normalized') }}
)
SELECT
    CONCAT(
        'location|',
        T.zip_code_prefix,
        '|',
        T.normalized_city,
        '|',
        T.normalized_state
    ) AS location_key,
    T.zip_code_prefix,
    T.normalized_city AS city,
    T.normalized_state AS state,
    L.representative_latitude,
    L.representative_longitude
FROM T
LEFT JOIN {{ ref('int_location_coordinates') }} AS L
    ON T.zip_code_prefix = L.zip_code_prefix
    AND T.normalized_city = L.normalized_city
    AND T.normalized_state = L.normalized_state