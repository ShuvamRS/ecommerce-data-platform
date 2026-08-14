{{ config(materialized='table') }}

SELECT
    M.municipality_key,
    P.year AS population_year,
    P.population
FROM {{ source('silver', 'ibge_municipality_population') }} AS P
INNER JOIN {{ ref('dim_municipality') }} AS M
    ON P.ibge_municipality_id = M.ibge_municipality_id