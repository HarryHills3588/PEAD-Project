{{
    config(
        unique_key='location_id'
    )
}}

with locations as (
    SELECT DISTINCT "location",
    created_at
    FROM {{ ref('process_facts')  }}
    WHERE "location" IS NOT NULL
)

SELECT 
    ROW_NUMBER() OVER (ORDER BY "location" DESC) as "location_id",
    "location",
    created_at
FROM "locations"

{% if is_incremental() %}
    WHERE created_at > (SELECT max(created_at) FROM {{ this }})
{% endif %}