WITH mql_count AS (
    SELECT COUNT(*) AS row_count
    FROM {{ ref('fact_mql') }}
),
mart_count AS (
    SELECT COUNT(*) AS row_count
    FROM {{ ref('mart_seller_acquisition') }}
)
SELECT
    MQL.row_count AS mql_row_count,
    MART.row_count AS mart_row_count
FROM mql_count AS MQL CROSS JOIN mart_count AS MART
WHERE MQL.row_count <> MART.row_count