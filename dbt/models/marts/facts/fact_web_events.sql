{{ config(materialized='table') }}

SELECT
    visitor_id,
    item_id,
    transaction_id,
    event_type,
    CAST(DATE_FORMAT(event_timestamp, 'yyyyMMdd') AS INT) AS event_date_key,
    DATE_FORMAT(event_timestamp, 'HH:mm:ss.SSS') AS event_time

FROM {{ source('silver', 'retailrocket_events') }}