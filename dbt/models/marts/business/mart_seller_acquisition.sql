{{ config(materialized='table') }}

SELECT
    MQL.marketing_qualified_lead_id,
    MQL.landing_page_id,
    MQL.lead_origin,
    MQL.first_contact_date_key,
    CD.marketing_qualified_lead_id IS NOT NULL AS is_closed_deal,
    CD.seller_key,
    CD.deal_won_date_key,
    DATEDIFF(
        TO_DATE(CAST(CD.deal_won_date_key AS STRING), 'yyyyMMdd'),
        TO_DATE(CAST(MQL.first_contact_date_key AS STRING), 'yyyyMMdd')
    ) AS days_to_close,
    CD.deal_won_date_key >= MQL.first_contact_date_key AS deal_chronology_valid,
    CD.sales_development_representative_id,
    CD.sales_representative_id,
    CD.business_segment,
    CD.lead_type,
    CD.lead_behaviour_profile,
    CD.has_company,
    CD.has_global_trade_item_number,
    CD.average_stock,
    CD.business_type,
    CD.declared_product_catalog_size,
    CD.declared_monthly_revenue

FROM {{ ref('fact_mql') }} AS MQL
    LEFT JOIN {{ ref('fact_closed_deals') }} AS CD
        ON MQL.marketing_qualified_lead_id
            = CD.marketing_qualified_lead_id