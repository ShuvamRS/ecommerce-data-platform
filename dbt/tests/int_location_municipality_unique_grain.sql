SELECT normalized_city, normalized_state
FROM {{ ref('int_location_municipality') }}
GROUP BY normalized_city, normalized_state
HAVING COUNT(*) > 1