-- Complaint type dimension for DOT 311 service requests.
-- Grain: one row per distinct (complaint_type, descriptor) combination.

WITH stg_311 AS (
    SELECT * FROM {{ ref('staging_311_secondary') }}
),

distinct_complaint_types AS (

    SELECT DISTINCT
        complaint_type,
        descriptor
    FROM stg_311
    WHERE complaint_type IS NOT NULL

),

enriched AS (

    SELECT
        complaint_type,
        descriptor,

        -- Derived category, based on keywords appearing in descriptor
        -- Order matters due to CASE WHEN structure (worth considering)
        -- Match is case insensitive

        CASE
            WHEN LOWER(descriptor) LIKE '%sighting %' THEN 'Rodent'
            WHEN LOWER(descriptor) LIKE '%handwashing%' THEN 'Hygine/Handwashing'
            WHEN LOWER(descriptor) LIKE '% hands %' THEN 'Hygine/Handwashing'
            WHEN LOWER(descriptor) LIKE '%prep%' THEN 'Facility'
            WHEN LOWER(descriptor) LIKE '%toilet%' THEN 'Toilet'
            WHEN LOWER(descriptor) LIKE '%1 or %' THEN 'Food Poisoning'
            WHEN LOWER(descriptor) LIKE '%2 or %' THEN 'Food Poisoning'
            WHEN LOWER(descriptor) LIKE '%3 or %' THEN 'Food Poisoning'
            WHEN LOWER(descriptor) LIKE '% rat %' THEN 'Rodent'
            WHEN LOWER(descriptor) LIKE '%rodent%' THEN 'Rodent'
            WHEN LOWER(descriptor) LIKE '%mouse%' THEN 'Rodent'
            WHEN LOWER(descriptor) LIKE '%worker%' THEN 'Worker issues'
            WHEN LOWER(descriptor) LIKE '%food%' THEN 'Food related'
            WHEN LOWER(descriptor) LIKE '%animal%' THEN 'Animal/Pets'
            WHEN LOWER(descriptor) LIKE '%permit%' THEN 'No permit/Liscence'
            WHEN LOWER(descriptor) LIKE '%odor%' THEN 'Odor'
            WHEN LOWER(descriptor) LIKE '%smoking%' THEN 'Smoking'
            WHEN LOWER(descriptor) LIKE '%ventilation%' THEN 'Ventilation'
            WHEN LOWER(descriptor) LIKE '%allergy%' THEN 'Allergy info'
            WHEN LOWER(descriptor) LIKE '%sewage%' THEN 'Sewage/Water/Plumbing'
            WHEN LOWER(descriptor) LIKE '%toxic%' THEN 'Toxic Chemicals/Materials'
            WHEN LOWER(descriptor) LIKE '%water%' THEN 'Sewage/Water/Plumbing'
            WHEN LOWER(descriptor) LIKE '%plumbing%' THEN 'Sewage/Water/Plumbing'
            WHEN LOWER(descriptor) LIKE '%pesticide%' THEN 'Toxic Chemicals/Materials'
            WHEN LOWER(descriptor) LIKE '%other%' THEN 'other'

            ELSE 'other'
        END AS complaint_category

    FROM distinct_complaint_types

),

dim_complaint_type AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'complaint_type', 'descriptor'
        ]) }} AS complaint_type_key,

        complaint_type AS complaint,
        descriptor,
        complaint_category
        

    FROM enriched

)

SELECT * FROM dim_complaint_type
