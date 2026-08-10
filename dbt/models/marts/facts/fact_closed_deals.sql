{{ config(materialized='table') }}

SELECT
    CD.marketing_qualified_lead_id,
    DS.seller_key,
    CD.sales_development_representative_id,
    CD.sales_representative_id,
    CAST(DATE_FORMAT(MQL.first_contact_date, 'yyyyMMdd') AS INT) AS first_contact_date_key,
    CAST(DATE_FORMAT(CD.deal_won_date, 'yyyyMMdd') AS INT) AS deal_won_date_key,
    DATE_FORMAT(CD.deal_won_date, 'HH:mm:ss') AS deal_won_time,
    CD.business_segment,
    CD.lead_type,
    CD.lead_behaviour_profile,
    CD.has_company,
    CD.has_global_trade_item_number,
    CD.average_stock,
    CD.business_type,
    CD.declared_product_catalog_size,
    CD.declared_monthly_revenue

FROM {{ source('silver', 'olist_closed_deals') }} AS CD
    INNER JOIN {{ ref('dim_seller') }} AS DS
        ON CD.seller_id = DS.seller_id
    INNER JOIN {{ source('silver', 'olist_marketing_qualified_leads') }} AS MQL
        ON CD.marketing_qualified_lead_id = MQL.marketing_qualified_lead_id