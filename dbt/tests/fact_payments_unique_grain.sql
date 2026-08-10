SELECT
    order_id,
    payment_sequence_number
FROM {{ ref('fact_payments') }}
GROUP BY
    order_id,
    payment_sequence_number
HAVING COUNT(*) > 1