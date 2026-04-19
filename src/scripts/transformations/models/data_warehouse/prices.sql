SELECT 
    ticker, 
    "time" AS "date",
    "open",
    "close",
    "high",
    "low",
    "volume"
FROM {{  ref('process_prices')  }}
WHERE "close" IS NOT NULL and ticker IS NOT NULL