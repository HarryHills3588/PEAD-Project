{{
    config(
        unique_key='ticker'
    )
}}

WITH sectors AS (
    SELECT * FROM {{  ref('sectors')  }}
),
exchanges AS (
    SELECT * FROM {{ ref('exchanges')  }}
),
locations AS (
    SELECT * FROM {{ ref('locations')  }}
)

SELECT 
    f.ticker,
    f.name,
    s.sector_id,
    e.exchange_id,
    l.location_id,
    f.created_at
FROM {{  ref('process_facts')  }} f
JOIN sectors s USING (sector)
JOIN exchanges e USING (exchange)
JOIN locations l USING ("location")

{% if is_incremental() %}
    WHERE f.created_at > (SELECT COALESCE(max(created_at), '1900-01-01') FROM {{ this }})
{% endif %}