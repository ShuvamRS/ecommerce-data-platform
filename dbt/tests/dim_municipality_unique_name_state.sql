SELECT municipality_name, state_code
FROM {{ ref('dim_municipality') }}
GROUP BY municipality_name, state_code
HAVING COUNT(*) > 1