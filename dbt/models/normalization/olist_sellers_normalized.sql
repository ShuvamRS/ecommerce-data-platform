{{ config(materialized='view') }}

WITH T AS (
    SELECT
        *,
        UPPER(TRIM(seller_state)) AS normalized_state,
        REGEXP_REPLACE(LOWER(TRIM(seller_city)), r'\s+', ' ') AS normalized_city
    FROM {{ source('silver', 'olist_sellers') }}
),
T1 AS (
    SELECT
        * EXCEPT (normalized_city),
        TRANSLATE(
            REPLACE(normalized_city, 'ã', 'ã'),
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