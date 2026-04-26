{{
    config(
        unique_key=['ticker', 'quarter_id']
    )
}}

WITH spy_returns AS (
    SELECT
        trading_day_seq     AS spy_seq,
        log_return          AS spy_return
    FROM {{ ref('daily_returns') }}
    WHERE ticker = 'SPY'
      AND log_return IS NOT NULL
      AND is_suspect_return = FALSE
),

estimation_pairs AS (
    SELECT
        ea.ticker,
        ea.quarter_id,
        ea.anchor_seq,
        dr.log_return   AS stock_return,
        sr.spy_return
    FROM {{ ref('event_anchors') }} ea
    JOIN {{ ref('daily_returns') }} dr
        ON  dr.ticker          = ea.ticker
        AND dr.trading_day_seq BETWEEN ea.est_window_start_seq
        AND ea.est_window_end_seq
        AND dr.log_return IS NOT NULL
        AND dr.is_suspect_return = FALSE
    JOIN spy_returns sr
        ON sr.spy_seq = dr.trading_day_seq
    WHERE ea.has_sufficient_history = TRUE
),

beta_raw AS (
    SELECT
        ticker,
        quarter_id,
        anchor_seq,
        REGR_SLOPE(stock_return, spy_return) AS beta,
        REGR_INTERCEPT(stock_return, spy_return) AS alpha,
        REGR_R2(stock_return, spy_return) AS r_squared,
        REGR_COUNT(stock_return, spy_return) AS obs_count
    FROM estimation_pairs
    GROUP BY ticker, quarter_id, anchor_seq
    HAVING REGR_COUNT(stock_return, spy_return) >= 30
)

SELECT
    ticker,
    quarter_id,
    anchor_seq,
    ROUND(GREATEST(-2.0, LEAST(4.0, beta))::NUMERIC, 4)  AS beta,
    ROUND(alpha::NUMERIC, 6)                               AS alpha,
    CASE
        WHEN r_squared >= 0.10 THEN 'GOOD'
        WHEN r_squared >= 0.05 THEN 'WEAK'
        ELSE 'POOR'
    END AS beta_quality
FROM beta_raw
