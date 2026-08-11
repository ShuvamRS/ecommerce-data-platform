WITH closed_deal_count AS (
    SELECT COUNT(*) AS row_count
    FROM {{ ref('fact_closed_deals') }}
),
mart_closed_deal_count AS (
    SELECT COUNT(*) AS row_count
    FROM {{ ref('mart_seller_acquisition') }}
    WHERE is_closed_deal = TRUE
)
SELECT
    CLOSED_DEAL.row_count AS fact_closed_deal_count,
    MART.row_count AS mart_closed_deal_count
FROM closed_deal_count AS CLOSED_DEAL CROSS JOIN mart_closed_deal_count AS MART
WHERE CLOSED_DEAL.row_count <> MART.row_count