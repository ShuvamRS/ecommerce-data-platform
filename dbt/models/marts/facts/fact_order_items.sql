{{ config(materialized='table') }}

SELECT
    OI.order_id,
    OI.order_item_sequence_number,
    DP.product_key,
    DS.seller_key,
    CAST(DATE_FORMAT(O.order_purchase_timestamp, 'yyyyMMdd') AS INT) AS order_purchase_date_key,
    DATE_FORMAT(O.order_purchase_timestamp, 'HH:mm:ss') AS order_purchase_time,
    CAST(DATE_FORMAT(OI.shipping_limit_date, 'yyyyMMdd') AS INT) AS shipping_limit_date_key,
    DATE_FORMAT(OI.shipping_limit_date, 'HH:mm:ss') AS shipping_limit_time,
    OI.price,
    OI.freight_value
FROM {{ source('silver', 'olist_order_items') }} AS OI
    INNER JOIN {{ source('silver', 'olist_orders') }} AS O
        ON OI.order_id = O.order_id
    INNER JOIN {{ ref('dim_product') }} AS DP
        ON OI.product_id = DP.product_id
    INNER JOIN {{ ref('dim_seller') }} AS DS
        ON OI.seller_id = DS.seller_id