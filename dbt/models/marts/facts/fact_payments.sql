{{ config(materialized='table') }}

SELECT
    P.order_id,
    P.payment_sequence_number,
    P.payment_type,
    P.payment_installment_count,
    P.payment_amount,
    CAST(DATE_FORMAT(O.order_purchase_timestamp, 'yyyyMMdd') AS INT) AS order_purchase_date_key,
    DATE_FORMAT(O.order_purchase_timestamp, 'HH:mm:ss') AS order_purchase_time

FROM {{ source('silver', 'olist_order_payments') }} AS P
    INNER JOIN {{ source('silver', 'olist_orders') }} AS O
        ON P.order_id = O.order_id