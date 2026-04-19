with locations as (
    SELECT DISTINCT "location"
    FROM {{ ref('process_facts')  }}
    WHERE "location" IS NOT NULL
)

SELECT 
    ROW_NUMBER() OVER (ORDER BY "location" DESC) as "location_id",
    "location"
FROM "locations"