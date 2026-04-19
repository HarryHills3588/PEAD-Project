with exchanges as (
    SELECT DISTINCT exchange
    FROM {{ ref('process_facts')  }}
    WHERE sector IS NOT NULL
)

SELECT 
    ROW_NUMBER() OVER (ORDER BY exchange DESC) as exchange_id,
    exchange
FROM exchanges