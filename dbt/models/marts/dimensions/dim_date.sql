{{ config(materialized='table') }}

WITH DATES AS (
SELECT TO_DATE(order_purchase_timestamp) AS DATE
FROM {{ source('silver', 'olist_orders') }}
UNION ALL
SELECT TO_DATE(order_approved_at) AS DATE
FROM {{ source('silver', 'olist_orders') }}
UNION ALL
SELECT TO_DATE(order_delivered_carrier_date) AS DATE
FROM {{ source('silver', 'olist_orders') }}
UNION ALL
SELECT TO_DATE(order_delivered_customer_date) AS DATE
FROM {{ source('silver', 'olist_orders') }}
UNION ALL
SELECT TO_DATE(order_estimated_delivery_date) AS DATE
FROM {{ source('silver', 'olist_orders') }}
UNION ALL
SELECT TO_DATE(shipping_limit_date) AS DATE
FROM {{ source('silver', 'olist_order_items') }}
UNION ALL
SELECT TO_DATE(review_creation_date) AS DATE
FROM {{ source('silver', 'olist_order_reviews') }}
UNION ALL
SELECT TO_DATE(review_answer_timestamp) AS DATE
FROM {{ source('silver', 'olist_order_reviews') }}
UNION ALL
SELECT TO_DATE(first_contact_date) AS DATE
FROM {{ source('silver', 'olist_marketing_qualified_leads') }}
UNION ALL
SELECT TO_DATE(deal_won_date) AS DATE
FROM {{ source('silver', 'olist_closed_deals') }}
UNION ALL
SELECT TO_DATE(timestamp_millis(timestamp)) AS DATE
FROM {{ source('silver', 'retailrocket_events') }}
), generated_dates AS (
    SELECT 
        EXPLODE(
            SEQUENCE(
                MIN(DATE),
                MAX(DATE),
                INTERVAL 1 DAY
            )
        ) AS calendar_date
    FROM DATES
)
SELECT
    CAST(DATE_FORMAT(calendar_date, 'yyyyMMdd') AS INT) AS date_key,
    calendar_date,
    YEAR(calendar_date) AS year,
    QUARTER(calendar_date) AS quarter,
    MONTH(calendar_date) AS month,
    DATE_FORMAT(calendar_date, 'MMMM') AS month_name,
    DAY(calendar_date) AS day,
    DAYOFWEEK(calendar_date) AS day_of_week,
    DATE_FORMAT(calendar_date, 'EEEE') AS day_name
FROM generated_dates