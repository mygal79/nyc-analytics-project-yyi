-- Fact table: DOT 311 service requests
-- Grain: one row per service request (request_id, controlled in staging model)

WITH stg_311 AS (
    SELECT * FROM {{ ref('staging_311_secondary') }}
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

dim_request_channel AS (
    SELECT * FROM {{ ref('dim_request_channel')}}
),

dim_complaint_type AS (
    SELECT * FROM {{ ref('dim_complaint_type')}}
),

-- Build initial CTE for fact table
fact AS (
    
    SELECT
        -- request_key (surrogate key)
        -- unique_key
        -- created_date_key
        -- closed_date_key
        -- location_key
        -- location_type
        -- complaint_type_key
        -- incident_address
        -- latitude
        -- longitude
        -- request_status
        -- is_closed
        -- request_channel_key
        -- resolution_description

    FROM stg_311 s

    -- Left join because you want all the rows from staging table..
    -- JOIN ON the itmes that make up surrogate key in the dimension
    LEFT JOIN dim_date created_d
        ON CAST(s.created_date AS DATE) = created_d.full_date
    LEFT JOIN dim_date closed_d
        ON CAST(s.closed_date AS DATE) = closed_d.full_date

    -- IS NOT DISTINCT FROM so a NULL zip/ council_district matches  
    -- Could leave out the NULL exception and make these =s
    LEFT JOIN dim_location l
        ON s.borough    IS NOT DISTINCT FROM l.borough
        
        AND s.zipcode   IS NOT DISTINCT FROM l.zipcode
    
    LEFT JOIN dim_rquest_channel rc
        ON s.method_of_submission IS NOT DISTINCT FROM rc.channel_type
        AND s.descriptor          IS NOT DISTINCT FROM rc.descriptor

    LEFT JOIN dim_rquest_channel rc
        ON s.complaint_type IS NOT DISTINCT FROM ct.complaint_type
        AND s.descriptor          IS NOT DISTINCT FROM ct.descriptor

)