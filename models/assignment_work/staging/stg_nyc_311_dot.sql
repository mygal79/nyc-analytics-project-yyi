-- Clean and standardize 311 DOT service request data
-- One row per service request
WITH
    source as (select * from {{ source('raw', 'source_service_requests_homework') }}),  -- Easier to refer to the dbt reference to a long name table this way

    cleaned as (
        select
            -- Get all columns from source, except ones we're transforming below
            -- To do cleaning on them or explicitly cast them as types just in case
            * except (
                unique_key,
                created_date,
                closed_date,
                agency,
                agency_name,
                complaint_type,
                descriptor,
                status,
                incident_zip,
                borough,
                incident_address,
                street_name,
                cross_street_1,
                cross_street_2,
                latitude,
                longitude,
                open_data_channel_type
            ),

            -- Identifiers
            cast(unique_key as string) as request_id,

            -- Date/Time
            cast(created_date as timestamp) as created_date,
            cast(closed_date as timestamp) as closed_date,

            -- Request details
            cast(agency as string) as agency,
            cast(agency_name as string) as agency_name,
            cast(complaint_type as string) as complaint_type,
            cast(descriptor as string) as descriptor,
            upper(trim(cast(status as string))) as status,

            -- Location - clean zip code, handling several common zip code data problems
            case
                when upper(trim(cast(incident_zip as string))) in ('N/A', 'NA')
                then null
                when upper(trim(cast(incident_zip as string))) = 'ANONYMOUS'
                then 'Anonymous'
                when length(cast(incident_zip as string)) = 5
                then cast(incident_zip as string)
                when length(cast(incident_zip as string)) = 9
                then cast(incident_zip as string)
                when
                    length(cast(incident_zip as string)) = 10
                    and regexp_contains(cast(incident_zip as string), r'^\d{5}-\d{4}')
                then cast(incident_zip as string)
                else null
            end as zip,

            -- Location - standardized borough, just in case
            case
                when upper(trim(borough)) in ('MANHATTAN', 'NEW YORK COUNTY')
                then 'Manhattan'
                when upper(trim(borough)) in ('BRONX', 'THE BRONX')
                then 'Bronx'
                when upper(trim(borough)) in ('BROOKLYN', 'KINGS COUNTY')
                then 'Brooklyn'
                when upper(trim(borough)) in ('QUEENS', 'QUEEN', 'QUEENS COUNTY')
                then 'Queens'
                when upper(trim(borough)) in ('STATEN ISLAND', 'RICHMOND COUNTY')
                then 'Staten Island'
                else 'UNKNOWN or CITYWIDE'
            end as borough,

            cast(incident_address as string) as incident_address,
            cast(street_name as string) as street_name,
            cast(cross_street_1 as string) as cross_street_1,
            cast(cross_street_2 as string) as cross_street_2,
            cast(latitude as decimal) as latitude,
            cast(longitude as decimal) as longitude,

            -- Clearer column name as well for this one
            cast(open_data_channel_type as string) as method_of_submission,

            -- Metadata
            current_timestamp() as _stg_loaded_at

        from source

        -- Filters
        where
            (agency = 'DOT' or agency_name like '%Transportation%')
            and unique_key is not null
            and created_date is not null
            and cast(created_date as date) >= date_sub(current_date(), interval 7 year)
            and borough is not null

        -- Deduplicate
        qualify
            row_number() over (partition by unique_key order by created_date desc) = 1
    )

select *
from
    cleaned
    -- All should be part of this table after running: stg_nyc_311_dot
    
