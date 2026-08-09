{{ config(materialized='view') }}

SELECT
    geolocation_zip_code_prefix AS zip_code_prefix,
    normalized_city,
    normalized_state,
    MEDIAN(geolocation_lat) AS representative_latitude,
    MEDIAN(geolocation_lng) AS representative_longitude
FROM {{ ref('olist_geolocation_normalized') }}
GROUP BY
    geolocation_zip_code_prefix,
    normalized_city,
    normalized_state