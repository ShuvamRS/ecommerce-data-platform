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
    M.municipality_key,
    C.representative_latitude,
    C.representative_longitude
FROM T
LEFT JOIN {{ ref('int_location_coordinates') }} AS C
    ON T.zip_code_prefix = C.zip_code_prefix
    AND T.normalized_city = C.normalized_city
    AND T.normalized_state = C.normalized_state
LEFT JOIN {{ ref('int_location_municipality') }} AS LM
    ON T.normalized_city = LM.normalized_city
    AND T.normalized_state = LM.normalized_state
LEFT JOIN {{ ref('dim_municipality') }} AS M
    ON LM.ibge_municipality_id = M.ibge_municipality_id