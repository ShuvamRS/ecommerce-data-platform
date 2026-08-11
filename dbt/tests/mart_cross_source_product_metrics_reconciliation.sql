WITH mart_count AS (
    SELECT COUNT(*) AS row_count
    FROM {{ ref('mart_cross_source_product_metrics') }}
),
bridge_count AS (
    SELECT COUNT(*) AS row_count
    FROM {{ source('silver', 'retailrocket_olist_item_bridge') }}
)
SELECT
    MART.row_count AS mart_row_count,
    BRIDGE.row_count AS bridge_row_count
FROM mart_count AS MART
CROSS JOIN bridge_count AS BRIDGE
WHERE MART.row_count <> BRIDGE.row_count