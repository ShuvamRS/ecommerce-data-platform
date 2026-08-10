{{ config(materialized='table') }}

WITH unresolved_locations AS (
    SELECT
        location_key,
        zip_code_prefix,
        city,
        state
    FROM {{ ref('dim_location') }}
    WHERE representative_latitude IS NULL
      AND representative_longitude IS NULL
)
SELECT
    unresolved.*,
    CASE
        WHEN NOT EXISTS (
            SELECT 1
            FROM {{ ref('olist_geolocation_normalized') }} AS geolocation_normalized
            WHERE unresolved.zip_code_prefix =
                  geolocation_normalized.geolocation_zip_code_prefix
        )
            THEN 'zip_code_prefix not found.'
        WHEN NOT EXISTS (
            SELECT 1
            FROM {{ ref('olist_geolocation_normalized') }} AS geolocation_normalized
            WHERE unresolved.zip_code_prefix =
                  geolocation_normalized.geolocation_zip_code_prefix
              AND unresolved.state =
                  geolocation_normalized.normalized_state
        )
            THEN 'state does not match.'
        ELSE 'city does not match.'
    END AS issue_description
FROM unresolved_locations AS unresolved