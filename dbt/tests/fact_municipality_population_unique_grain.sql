SELECT municipality_key, population_year
FROM {{ ref('fact_municipality_population') }}
GROUP BY municipality_key, population_year
HAVING COUNT(*) > 1