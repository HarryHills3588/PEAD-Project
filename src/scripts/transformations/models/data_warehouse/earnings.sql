WITH surprise_labels AS (
    SELECT * FROM {{  ref('surprise_labels')  }}
),
quarters AS (
    SELECT * FROM {{  ref('quarters')  }}
)

SELECT 
    e.ticker,
    q.fiscal_period,
    e."epsActual",
    e."epsEstimated",
    e.surprise,
    sl.surprise_label
FROM {{  ref('process_fmp_earn')  }} e
JOIN quarters q USING (fiscal_period)
JOIN surprise_labels sl USING (surprise_label)