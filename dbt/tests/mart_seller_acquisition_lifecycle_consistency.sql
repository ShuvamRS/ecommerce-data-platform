SELECT *
FROM {{ ref('mart_seller_acquisition') }}
WHERE
(
    is_closed_deal = FALSE
    AND (
        seller_key IS NOT NULL
        OR deal_won_date_key IS NOT NULL
        OR days_to_close IS NOT NULL
        OR deal_chronology_valid IS NOT NULL
    )
)
OR
(
    is_closed_deal = TRUE
    AND (
        seller_key IS NULL
        OR deal_won_date_key IS NULL
        OR days_to_close IS NULL
        OR deal_chronology_valid IS NULL
    )
)