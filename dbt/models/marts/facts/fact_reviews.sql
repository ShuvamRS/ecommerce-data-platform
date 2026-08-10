{{ config(materialized='table') }}

SELECT 
    R.review_id,
    R.order_id,
    R.review_score,
    R.review_comment_title,
    R.review_comment_message,
    CAST(DATE_FORMAT(O.order_purchase_timestamp, 'yyyyMMdd') AS INT) AS order_purchase_date_key,
    CAST(DATE_FORMAT(R.review_creation_date, 'yyyyMMdd') AS INT) AS review_creation_date_key,
    DATE_FORMAT(R.review_creation_date, 'HH:mm:ss') AS review_creation_time,
    CAST(DATE_FORMAT(R.review_answer_timestamp, 'yyyyMMdd') AS INT) AS review_answer_date_key,
    DATE_FORMAT(R.review_answer_timestamp, 'HH:mm:ss') AS review_answer_time

FROM {{ source('silver', 'olist_order_reviews') }} AS R
    INNER JOIN {{ source('silver', 'olist_orders') }} AS O
        ON R.order_id = O.order_id