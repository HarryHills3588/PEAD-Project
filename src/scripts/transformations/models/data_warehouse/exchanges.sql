{{
    config(
        unique_key='exchange_id'
    )
}}

with exchanges as (
    SELECT DISTINCT exchange,
    created_at
    FROM {{ ref('process_facts')  }}
    WHERE sector IS NOT NULL
)

SELECT 
    ROW_NUMBER() OVER (ORDER BY exchange DESC) as exchange_id,
    exchange,
    created_at
FROM exchanges

{% if is_incremental() %}
    WHERE created_at > (SELECT max(created_at) FROM {{ this }})
{% endif %}