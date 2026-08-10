SELECT
    order_id,
    order_item_sequence_number
FROM {{ ref('fact_order_items') }}
GROUP BY
    order_id,
    order_item_sequence_number
HAVING COUNT(*) > 1