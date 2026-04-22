{{
    config(
        unique_key=['ticker', 'quarter_id']
    )
}}

WITH surprise_labels AS (
    SELECT * FROM {{  ref('surprise_labels')  }}
),
quarters AS (
    SELECT * FROM {{  ref('quarters')  }}
),
joined AS (
    SELECT
        e.ticker,
        q.quarter_id,
        e."epsActual",
        e."epsEstimated",
        e.surprise,
        sl.surprise_label,
        q.created_at,
        e."date"
    FROM {{  ref('process_fmp_earn')  }} e
    JOIN quarters q USING (fiscal_period)
    JOIN surprise_labels sl USING (surprise_label)

    {% if is_incremental() %}
        WHERE q.created_at > (SELECT COALESCE(max(created_at), '1900-01-01') FROM {{ this }})
    {% endif %}
)

SELECT DISTINCT ON (ticker, quarter_id)
    ticker,
    quarter_id,
    "epsActual",
    "epsEstimated",
    surprise,
    surprise_label,
    created_at
FROM joined
ORDER BY ticker, quarter_id, "date" DESC