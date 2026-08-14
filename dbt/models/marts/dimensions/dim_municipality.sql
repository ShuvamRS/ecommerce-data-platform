{{ config(materialized='table') }}

SELECT
    CONCAT(
        'municipality|',
        CAST(ibge_municipality_id AS STRING)
    ) AS municipality_key,
    ibge_municipality_id,
    municipality_name_normalized AS municipality_name,
    state_code
FROM {{ source('silver', 'ibge_municipalities') }}