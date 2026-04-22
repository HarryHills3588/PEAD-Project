{{
    config(
        unique_key=['ticker', 'date']
    )
}}

SELECT 
    ticker, 
    "time" AS "date",
    "open",
    "close",
    "high",
    "low",
    "volume",
    created_at
FROM {{  ref('process_prices')  }}
WHERE "close" IS NOT NULL and ticker IS NOT NULL

{% if is_incremental() %}
    AND created_at > (SELECT COALESCE(max(created_at), '1900-01-01') FROM {{ this }})
{% endif %}