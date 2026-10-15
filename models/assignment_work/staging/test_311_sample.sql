-- Quick test to verify source connection works
select unique_key, created_date, complaint_type, borough
from {{ source("raw", "source_service_requests_homework") }}
