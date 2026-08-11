{{ config(materialized='table') }}

WITH item_summary AS (
    SELECT
        order_id,
        COUNT(*) AS item_count,
        SUM(price) AS total_item_price,
        SUM(freight_value) AS freight_amount
    FROM {{ ref('fact_order_items') }}
    GROUP BY order_id
),
payment_summary AS (
    SELECT
        order_id,
        SUM(payment_amount) AS total_payment_amount,
        MAX(payment_installment_count) > 1 AS has_multi_installment_payment
    FROM {{ ref('fact_payments') }}
    GROUP BY order_id
),
review_summary AS (
    SELECT
        order_id,
        COUNT(*) AS review_count,
        AVG(review_score) AS average_review_score,
        MAX(
            CASE
                WHEN NULLIF(TRIM(review_comment_title), '') IS NOT NULL
                  OR NULLIF(TRIM(review_comment_message), '') IS NOT NULL
                    THEN 1
                ELSE 0
            END) = 1 AS has_written_review_comment
    FROM {{ ref('fact_reviews') }}
    GROUP BY order_id
)
SELECT
    O.order_id,
    O.customer_key,
    O.customer_location_key,
    O.order_status,
    O.order_purchase_date_key,
    O.order_delivered_customer_date_key,
    O.order_estimated_delivery_date_key,
    DATEDIFF(
        DELIVERED_DATE.calendar_date,
        PURCHASE_DATE.calendar_date
    ) AS delivery_days,
    DATEDIFF(
        DELIVERED_DATE.calendar_date,
        ESTIMATED_DATE.calendar_date
    ) AS delivery_vs_estimate_days,
    COALESCE(I.item_count, 0) AS item_count,
    I.total_item_price,
    I.freight_amount,
    P.total_payment_amount,
    COALESCE(P.has_multi_installment_payment, FALSE) AS has_multi_installment_payment,
    COALESCE(R.review_count, 0) AS review_count,
    R.average_review_score,
    COALESCE(R.has_written_review_comment, FALSE) AS has_written_review_comment

FROM {{ ref('fact_orders') }} AS O
    LEFT JOIN item_summary AS I
        ON O.order_id = I.order_id
    LEFT JOIN payment_summary AS P
        ON O.order_id = P.order_id
    LEFT JOIN review_summary AS R
        ON O.order_id = R.order_id
    LEFT JOIN {{ ref('dim_date') }} AS PURCHASE_DATE
        ON O.order_purchase_date_key = PURCHASE_DATE.date_key
    LEFT JOIN {{ ref('dim_date') }} AS DELIVERED_DATE
        ON O.order_delivered_customer_date_key = DELIVERED_DATE.date_key
    LEFT JOIN {{ ref('dim_date') }} AS ESTIMATED_DATE
        ON O.order_estimated_delivery_date_key = ESTIMATED_DATE.date_key