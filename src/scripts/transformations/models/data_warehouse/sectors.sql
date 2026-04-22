{{
    config(
        unique_key='sector_id'
    )
}}

with sectors as (
    SELECT DISTINCT sector,
    created_at
    FROM {{ ref('process_facts')  }}
    WHERE sector IS NOT NULL
)

SELECT 
    ROW_NUMBER() OVER (ORDER BY sector DESC) as sector_id,
    sector,
    created_at
FROM sectors

{% if is_incremental() %}
    WHERE created_at > (SELECT max(created_at) FROM {{ this }})
{% endif %}