{{ config(materialized='view') }}

WITH T AS (
    SELECT
        *,
        UPPER(TRIM(geolocation_state)) AS normalized_state,
        REGEXP_REPLACE(LOWER(TRIM(geolocation_city)), r'\s+', ' ') AS normalized_city
    FROM {{source('silver', 'olist_geolocation')}}
),
T1 AS (
    SELECT
    * EXCEPT (normalized_city),
        TRANSLATE(
            normalized_city,
            'áàâãäéèêëíìîïóòôõöúùûüç',
            'aaaaaeeeeiiiiooooouuuuc'
        ) AS normalized_city
    FROM T
)
SELECT
    * EXCEPT (normalized_city),
    CASE
        WHEN REGEXP_LIKE(
            normalized_city,
            r'\s*-\s*' || LOWER(normalized_state) || r'$'
        )
        THEN REGEXP_REPLACE(
            normalized_city,
            r'\s*-\s*' || LOWER(normalized_state) || r'$',
            ''
        )
        WHEN REGEXP_LIKE(
            normalized_city,
            r'\s*/\s*' || LOWER(normalized_state) || r'$'
        )
        THEN REGEXP_REPLACE(
            normalized_city,
            r'\s*/\s*' || LOWER(normalized_state) || r'$',
            ''
        )
        WHEN REGEXP_LIKE(
            normalized_city,
            r'\s+' || LOWER(normalized_state) || r'$'
        )
        THEN REGEXP_REPLACE(
            normalized_city,
            r'\s+' || LOWER(normalized_state) || r'$',
            ''
        )
        ELSE normalized_city
    END AS normalized_city
FROM T1