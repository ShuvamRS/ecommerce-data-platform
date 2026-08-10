WITH silver_count AS (
    SELECT COUNT(*) AS row_count
    FROM {{ source('silver', 'retailrocket_events') }}
),
gold_count AS (
    SELECT COUNT(*) AS row_count
    FROM {{ ref('fact_web_events') }}
)
SELECT
    S.row_count AS silver_row_count,
    G.row_count AS gold_row_count
FROM silver_count AS S
CROSS JOIN gold_count AS G
WHERE S.row_count <> G.row_count