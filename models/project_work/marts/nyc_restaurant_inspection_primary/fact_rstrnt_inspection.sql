-- Fact table: NYC DOHMH restaurant inspections, 2020-2025
-- Grain: one row per restaurant inspection

WITH stg_restaurant AS (
    SELECT * FROM {{ ref('staging_restaurant_primary') }}
),

-- All the dimensions in their own CTEs for easy reference
dim_date AS (
    SELECT * 
    FROM {{ ref('dim_date') }}
),

dim_location AS (
    SELECT * 
    FROM {{ ref('dim_location') }}
),

dim_restaurant AS (
    SELECT * FROM {{ ref('dim_restaurant') }}
),

dim_violation_type AS (
    SELECT * FROM {{ ref('dim_violation_type') }}
),

fact AS (
    
    SELECT
        -- Primary key: one per violation row
        -- Inspection identifier: shared by all violation rows of one inspection
        {{ dbt_utils.generate_surrogate_key(['s.camis', 's.inspection_date', 's.violation_code']) }} AS inspection_key,

                -- Foreign keys (from the dimensions, with unknown fallbacks)
        COALESCE(insp_d.date_key, '-1')     AS inspection_date_key,
        COALESCE(rec_d.date_key,  '-1')     AS record_date_key,
        COALESCE(l.location_key,  '-1')     AS location_key,
        COALESCE(r.restaurant_key, '-1')    AS restaurant_key,
        CASE
            WHEN s.violation_code IS NULL THEN '-2'
            ELSE COALESCE(v.violation_type_key, '-1')
        END                                 AS violation_type_key,

        -- Degenerate dimension
        s.camis AS camis_id,

        -- Inspection attributes and measures
        s.violation_description,
        s.action AS outcome_action,
        s.score,
        s.grade,
        s.cuisine_description,
        s.latitude,
        s.longitude,
        s.nta

    FROM stg_restaurant s

    -- LEFT JOINs keep every row from staging, even if a dimension has no match.
    -- Join on the same columns the dimension uses to build its surrogate key.
    LEFT JOIN dim_date insp_d 
        ON CAST (s.inspection_date AS DATE) = insp_d.full_date
    LEFT JOIN dim_date rec_d
        ON CAST (s.record_date AS DATE) = rec_d.full_date

    -- IS NOT DISTINCT FROM so a NULL zipcode still matches the dimension row with a NULL zipcode
    LEFT JOIN dim_location l
        ON  s.borough IS NOT DISTINCT FROM l.borough
        AND s.zipcode IS NOT DISTINCT FROM l.zipcode

    LEFT JOIN dim_restaurant r
        ON s.camis = r.camis_ID

    LEFT JOIN dim_violation_type v
        ON s.violation_code = v.violation_code
)

SELECT * FROM fact