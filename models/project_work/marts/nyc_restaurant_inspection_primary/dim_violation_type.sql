-- Violation type dimension for NYC DOHMH restaurant inspections.
-- Grain: one row per violation type (violation_code)

WITH stg_restaurant AS (
    SELECT * FROM {{ ref('staging_restaurant_primary') }}
),

distinct_violation_type AS (
    SELECT DISTINCT
        violation_code,
        critical_flag
    FROM stg_restaurant
    WHERE violation_code IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY violation_code ORDER BY inspection_date DESC, record_date DESC) = 1    
),

dim_violation_type AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['violation_code']) }} AS violation_type_key,
        violation_code,
        critical_flag
    FROM distinct_violation_type
),

special_members AS (
    -- Used by the fact table when a violation code cannot be matched
    SELECT
        '-1'                         AS violation_type_key,
        'UNKNOWN'                    AS violation_code,
        'Unknown'                    AS critical_flag

    UNION ALL

    -- Used by the fact table for inspections with no violations cited (violation_code IS NULL)
    SELECT
        '-2'                         AS violation_type_key,
        'NONE'                       AS violation_code,
        'Not Applicable'             AS critical_flag
)

SELECT * FROM dim_violation_type
UNION ALL
SELECT * FROM special_members