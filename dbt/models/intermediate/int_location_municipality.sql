{{ config(materialized='view') }}

WITH olist_locations AS (
    SELECT normalized_city, normalized_state
    FROM {{ ref('olist_customers_normalized') }}

    UNION

    SELECT normalized_city, normalized_state
    FROM {{ ref('olist_sellers_normalized') }}
)

SELECT
    L.normalized_city,
    L.normalized_state,
    M.ibge_municipality_id
FROM olist_locations AS L
LEFT JOIN {{ source('silver', 'ibge_municipalities') }} AS M
    ON L.normalized_city = M.municipality_name_normalized
    AND L.normalized_state = M.state_code