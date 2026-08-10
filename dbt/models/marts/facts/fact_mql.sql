{{ config(materialized='table') }}

SELECT
    marketing_qualified_lead_id,
    landing_page_id,
    lead_origin,
    CAST(DATE_FORMAT(first_contact_date, 'yyyyMMdd') AS INT) AS first_contact_date_key

FROM {{ source('silver', 'olist_marketing_qualified_leads') }}