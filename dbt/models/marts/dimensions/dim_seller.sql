{{ config(materialized='table') }}

WITH sellers_with_location AS (
    SELECT
        sellers_normalized.seller_id,
        dim_location.location_key AS seller_location_key
    FROM {{ref('olist_sellers_normalized')}} AS sellers_normalized INNER JOIN {{ref("dim_location")}} AS dim_location
        ON sellers_normalized.normalized_city = dim_location.city
        AND sellers_normalized.normalized_state = dim_location.state
        AND sellers_normalized.seller_zip_code_prefix = dim_location.zip_code_prefix
)
SELECT
    CONCAT(
        'seller|',
        int_seller_population.seller_id
    ) AS seller_key,
    int_seller_population.seller_id,
    sellers_with_location.seller_location_key
FROM {{ ref('int_seller_population') }} AS int_seller_population
    LEFT JOIN sellers_with_location
    ON int_seller_population.seller_id = sellers_with_location.seller_id