WITH deduplicated as (
    SELECT DISTINCT ON (symbol, "date") *
    FROM {{  source('fmp','fmp_earnings')  }}
),
casted AS (
    SELECT 
        symbol::varchar(10) AS ticker, 
        "date"::date,
        "epsActual"::numeric(20,4),
        "epsEstimated"::numeric(20,4),
        "revenueActual"::numeric(20,2)::bigint,
        "revenueEstimated"::numeric(20,4)::bigint,
        "lastUpdated"::date
    FROM deduplicated
    WHERE "epsActual" IS NOT NULL
        AND "epsEstimated" IS NOT NULL
        AND "revenueEstimated" IS NOT NULL
        AND "revenueActual" IS NOT NULL
)

SELECT 
    *, 
    EXTRACT(QUARTER FROM "date") AS "quarter",
    ("epsActual" - "epsEstimated")::numeric(10,4) AS surprise,
    CASE
        WHEN "epsEstimated" = 0 THEN NULL
        WHEN ("epsActual" - "epsEstimated") / ABS("epsEstimated") * 100 > 1.0 THEN 'BEAT'
        WHEN ("epsActual" - "epsEstimated") / ABS("epsEstimated") * 100 < -1.0 THEN 'MISS'
        ELSE 'MEET'
    END::TEXT AS surprise_label,
    EXTRACT(YEAR FROM "date")::int || '-Q'|| EXTRACT(QUARTER FROM "date")::int AS fiscal_period
FROM casted