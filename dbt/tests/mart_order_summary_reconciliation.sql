WITH mart_metrics AS (
    SELECT
        COUNT(*) AS order_count,
        SUM(item_count) AS item_count,
        SUM(total_payment_amount) AS total_payment_amount,
        SUM(review_count) AS review_count
    FROM {{ ref('mart_order_summary') }}
),
expected_metrics AS (
    SELECT
        (SELECT COUNT(*) FROM {{ ref('fact_orders') }}) AS order_count,
        (SELECT COUNT(*) FROM {{ ref('fact_order_items') }}) AS item_count,
        (SELECT SUM(payment_amount) FROM {{ ref('fact_payments') }}) AS total_payment_amount,
        (SELECT COUNT(*) FROM {{ ref('fact_reviews') }}) AS review_count
)

SELECT
    MART.order_count,
    EXPECTED.order_count AS expected_order_count,
    MART.item_count,
    EXPECTED.item_count AS expected_item_count,
    MART.total_payment_amount,
    EXPECTED.total_payment_amount AS expected_total_payment_amount,
    MART.review_count,
    EXPECTED.review_count AS expected_review_count

FROM mart_metrics AS MART
    CROSS JOIN expected_metrics AS EXPECTED

WHERE MART.order_count <> EXPECTED.order_count
   OR MART.item_count <> EXPECTED.item_count
   OR MART.total_payment_amount <> EXPECTED.total_payment_amount
   OR MART.review_count <> EXPECTED.review_count