-- Clean and standardize 311 DOT service request data
-- One row per service request

WITH source AS (
   SELECT * FROM {{ source('raw', 'source_nyc_dob_job_apps') }}
), -- Easier to refer to the dbt reference to a long name table this way

cleaned AS (
   SELECT
       -- Get all columns from source, except ones we're transforming below
       -- To do cleaning on them or explicitly cast them as types just in case
       * EXCEPT (
           job_filing_number,
           filing_date,
           signoff_date,
           filing_status,
           applicant_business_name,
           job_type,
	   job_description,
           house_no,
	    zip,
           borough,
           postcode,
           street_name,
           census_tract,
           nta,
           latitude,
           longitude,
           building_type, 
            work_on_floor
       ),

       -- Identifiers
       CAST(job_filing_number AS STRING) AS job_filing_num,

       -- Date/Time
       CAST(filing_date AS TIMESTAMP) AS filing_date,
       CAST(signoff_date AS TIMESTAMP) AS signoff_date,

       -- Job details
       CAST(applicant_business_name AS STRING) AS applicant_name,
       CAST(building_type AS STRING) AS building_type,
       CAST(job_type AS STRING) AS job_type,
       CAST(job_description AS STRING) AS job_descriptor,
       UPPER(TRIM(CAST(filing_status AS STRING))) AS filing_status,

       -- Location - clean zip code, handling several common zip code data problems
       CASE
           WHEN UPPER(TRIM(CAST(postcode AS STRING))) IN ('N/A', 'NA') THEN NULL
           WHEN UPPER(TRIM(CAST(postcode AS STRING))) = 'ANONYMOUS' THEN 'Anonymous'
           WHEN LENGTH(CAST(postcode AS STRING)) = 5 THEN CAST(postcode AS STRING)
           WHEN LENGTH(CAST(postcode AS STRING)) = 9 THEN CAST(postcode AS STRING)
           WHEN LENGTH(CAST(postcode AS STRING)) = 10
               AND REGEXP_CONTAINS(CAST(postcode AS STRING), r'^\d{5}-\d{4}')
           THEN CAST(postcode AS STRING)
           ELSE NULL
       END AS postcode,
       

       -- Location - standardized borough, just in case
       CASE
           WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
           WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
           WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
           WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
           WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
           ELSE 'UNKNOWN or CITYWIDE'
       END AS borough,

       CAST(house_no AS STRING) AS address_house_no,
       CAST(street_name AS STRING) AS street_name,
       CAST(census_tract AS STRING) AS census_tract,
       CAST(work_on_floor AS STRING) AS work_on_floor,
       CAST(latitude AS DECIMAL) AS latitude,
       CAST(longitude AS DECIMAL) AS longitude,
       CAST(zip AS STRING) AS applicant_zip,


       -- Clearer column name as well for this one
       CAST(nta AS STRING) AS neighborhood,
       CAST(postcode AS STRING) AS zipcode,

       -- Metadata
       CURRENT_TIMESTAMP() AS _stg_loaded_at

   FROM source

   -- Filters
   
   WHERE job_filing_number IS NOT NULL
   AND filing_date IS NOT NULL
   AND CAST(filing_date AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 YEAR)
   AND borough IS NOT NULL
   AND postcode IS NOT NULL

   -- Deduplicate
   QUALIFY ROW_NUMBER() OVER (PARTITION BY job_filing_number ORDER BY filing_date DESC) = 1
)

SELECT * FROM cleaned
-- All should be part of this table after running: stg_nyc_dob_job_apps

