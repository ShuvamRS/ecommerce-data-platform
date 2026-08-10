{{ config(materialized='table') }}

SELECT
    CONCAT(
        'product|',
        product_id
    ) AS product_key,
    product_id,
    product_category_name_portuguese,
    product_category_name_english,
    product_name_length,
    product_description_length,
    product_photo_count,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM {{ source('silver', 'olist_products') }}