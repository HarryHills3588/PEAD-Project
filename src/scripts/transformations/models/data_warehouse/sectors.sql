with sectors as (
    SELECT DISTINCT sector
    FROM {{ ref('process_facts')  }}
    WHERE sector IS NOT NULL
)

SELECT 
    ROW_NUMBER() OVER (ORDER BY sector DESC) as sector_id,
    sector
FROM sectors