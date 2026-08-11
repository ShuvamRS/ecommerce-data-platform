{{ config(materialized='table') }}

WITH event_summary AS (
    SELECT
        item_id,
        SUM(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END) AS view_event_count,
        SUM(CASE WHEN event_type = 'addtocart' THEN 1 ELSE 0 END) AS addtocart_event_count,
        SUM(CASE WHEN event_type = 'transaction' THEN 1 ELSE 0 END) AS transaction_event_count
    FROM {{ ref('fact_web_events') }}
    GROUP BY item_id
),
product_summary AS (
    SELECT
        product_key,
        COUNT(*) AS olist_item_count,
        SUM(price) AS total_item_price
    FROM {{ ref('fact_order_items') }}
    GROUP BY product_key
)
SELECT
    P.product_key,
    B.retailrocket_item_id,
    E.view_event_count,
    E.addtocart_event_count,
    E.transaction_event_count,
    S.olist_item_count,
    S.total_item_price
FROM {{ source('silver', 'retailrocket_olist_item_bridge') }} AS B
    INNER JOIN {{ ref('dim_product') }} AS P
        ON B.olist_product_id = P.product_id
    LEFT JOIN event_summary AS E
        ON B.retailrocket_item_id = E.item_id
    LEFT JOIN product_summary AS S
        ON P.product_key = S.product_key