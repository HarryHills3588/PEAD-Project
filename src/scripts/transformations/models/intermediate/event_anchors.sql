{{
    config(
        unique_key=['ticker', 'quarter_id']
    )
}}

WITH earnings_with_date AS (
    SELECT DISTINCT ON (e.ticker, q.quarter_id)
        e.ticker,
        q.quarter_id,
        e."epsActual",
        e."epsEstimated",
        e.surprise,
        e.surprise_label,
        q.fiscal_period,
        e."date"::DATE AS earnings_date
    FROM {{ ref('earnings') }} e
    JOIN {{ ref('quarters') }} q
        USING (quarter_id)
    WHERE e."epsEstimated" IS NOT NULL
      AND e."epsEstimated" != 0
      AND e.surprise IS NOT NULL
      AND e."date" IS NOT NULL
    ORDER BY e.ticker, q.quarter_id, e."date" DESC
),

anchored AS (
    SELECT
        eb.ticker,
        eb.quarter_id,
        eb."epsActual",
        eb."epsEstimated",
        eb.surprise,
        eb.surprise_label,
        eb.fiscal_period,
        eb.earnings_date,
        MIN(dr.trading_day_seq) AS anchor_seq,
        MIN(dr.price_date) AS anchor_date
    FROM earnings_with_date eb
    JOIN {{ ref('daily_returns') }} dr
        ON  dr.ticker     = eb.ticker
        AND dr.price_date >= eb.earnings_date
    GROUP BY
        eb.ticker, eb.quarter_id, eb."epsActual", eb."epsEstimated",
        eb.surprise, eb.surprise_label, eb.fiscal_period, eb.earnings_date
)

SELECT
    ticker,
    quarter_id,
    earnings_date,
    ROUND(surprise::NUMERIC, 4) AS surprise_pct,
    surprise_label,
    anchor_seq,
    GREATEST(1, anchor_seq - 70) AS est_window_start_seq,
    anchor_seq - 10 AS est_window_end_seq,
    CASE
        WHEN anchor_seq - 10 >= 30 THEN TRUE
        ELSE FALSE
    END AS has_sufficient_history

FROM anchored
