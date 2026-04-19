WITH deduplicated AS (
    SELECT DISTINCT ON (ticker) *
    FROM {{  source('raw', 'facts')  }}
)
SELECT
    ticker::varchar(45),
    "name"::varchar(45),
    sector::varchar(90),
    industry::varchar(45),
    exchange::varchar(45),
    "location"::varchar(45)
FROM deduplicated