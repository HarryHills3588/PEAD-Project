WITH deduplicated AS (
    SELECT DISTINCT ON (ticker, "time") * 
    FROM {{  source("raw", "prices")  }}
)
SELECT 
    ticker::varchar(45),
    "open"::numeric(10,2),
    "close"::numeric(10,2),
    "high"::numeric(10,2),
    "low"::numeric(10,2),
    "volume"::bigint,
    "time"::date,
    current_timestamp as created_at
FROM deduplicated

-- TODO: Look at prices and make sure they have {{ config }} for incrementable 