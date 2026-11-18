-- Restaurant dimension for restaurant inspections.
-- Grain: one row per restaurant (camis_id).
-- We added a qualifier that will keep just the latest version of each restaurant, as the camis doesnt change, but the name or address can.

WITH stg_restaurant AS (
    SELECT * FROM {{ ref('staging_restaurant_primary') }}
),

distinct_restaurant AS (
    SELECT DISTINCT
        camis AS camis_id,
        dba AS dba_name,
        NULLIF(ARRAY_TO_STRING([TRIM(building), TRIM(street)], ' '), '') AS restaurant_address, -- to join the fields of building and street.
        bin                                      
    FROM stg_restaurant
    WHERE camis IS NOT NULL   
    QUALIFY ROW_NUMBER() OVER (PARTITION BY camis ORDER BY inspection_date DESC) = 1 
),

dim_restaurant AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['camis_id']) }} AS restaurant_key,
        camis_id,
        dba_name,
        restaurant_address,
        bin
    FROM distinct_restaurant
),

unknown_member AS (
    -- Used by the fact table when an inspection cannot be matched to a restaurant
    SELECT
        '-1'                 AS restaurant_key,
        CAST(NULL AS STRING) AS camis_id,
        'UNKNOWN'            AS dba_name,
        CAST(NULL AS STRING) AS restaurant_address,        
        CAST(NULL AS STRING) AS bin
)
SELECT * FROM dim_restaurant
UNION ALL
SELECT * FROM unknown_member