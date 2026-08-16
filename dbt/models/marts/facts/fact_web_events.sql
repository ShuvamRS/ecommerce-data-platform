{{ config(materialized='table') }}

SELECT
    E.visitor_id,
    E.item_id,
    P.product_key,
    E.transaction_id,
    E.event_type,
    CAST(DATE_FORMAT(E.event_timestamp, 'yyyyMMdd') AS INT) AS event_date_key,
    DATE_FORMAT(E.event_timestamp, 'HH:mm:ss.SSS') AS event_time

FROM {{ source('silver', 'retailrocket_events') }} AS E
LEFT JOIN {{ source('silver', 'retailrocket_olist_item_bridge') }} AS B
    ON E.item_id = B.retailrocket_item_id
LEFT JOIN {{ ref('dim_product') }} AS P
    ON B.olist_product_id = P.product_id