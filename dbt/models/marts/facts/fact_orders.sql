{{ config(materialized='table') }}

SELECT
    O.order_id,
    O.order_status,
    C.customer_key,
    C.customer_location_key,
    CAST(DATE_FORMAT(O.order_purchase_timestamp, 'yyyyMMdd') AS INT) AS order_purchase_date_key,
    DATE_FORMAT(O.order_purchase_timestamp, 'HH:mm:ss') AS order_purchase_time,
    CAST(DATE_FORMAT(O.order_approved_at, 'yyyyMMdd') AS INT) AS order_approved_date_key,
    DATE_FORMAT(O.order_approved_at, 'HH:mm:ss') AS order_approved_time,
    CAST(DATE_FORMAT(O.order_delivered_carrier_date, 'yyyyMMdd') AS INT) AS order_delivered_carrier_date_key,
    DATE_FORMAT(O.order_delivered_carrier_date, 'HH:mm:ss') AS order_delivered_carrier_time,
    CAST(DATE_FORMAT(O.order_delivered_customer_date, 'yyyyMMdd') AS INT) AS order_delivered_customer_date_key,
    DATE_FORMAT(O.order_delivered_customer_date, 'HH:mm:ss') AS order_delivered_customer_time,
    CAST(DATE_FORMAT(O.order_estimated_delivery_date, 'yyyyMMdd') AS INT) AS order_estimated_delivery_date_key,
    DATE_FORMAT(O.order_estimated_delivery_date, 'HH:mm:ss') AS order_estimated_delivery_time

FROM {{ source('silver', 'olist_orders') }} O
    INNER JOIN {{ ref('int_order_context') }} C
        ON O.order_id = C.order_id