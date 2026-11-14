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
        -- FACT's own surrogate key, from the grain (this is deduped in staging)



)