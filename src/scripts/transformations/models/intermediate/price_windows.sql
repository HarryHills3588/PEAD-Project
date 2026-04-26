{{
    config(
        unique_key=['ticker', 'quarter_id']
    )
}}

WITH spy_prices AS (
    SELECT
        trading_day_seq     AS spy_seq,
        close_price         AS spy_close
    FROM {{ ref('daily_returns') }}
    WHERE ticker = 'SPY'
      AND is_suspect_return = FALSE
),

event_prices AS (
    SELECT
        ea.ticker,
        ea.quarter_id,
        ea.earnings_date,
        ea.surprise_pct,
        ea.surprise_label,
        ea.anchor_seq,

        p0.close_price AS stock_d0,
        p7.close_price AS stock_d7,
        p30.close_price AS stock_d30,

        s0.spy_close AS spy_d0,
        s7.spy_close AS spy_d7,
        s30.spy_close AS spy_d30

    FROM {{ ref('event_anchors') }} ea
    JOIN {{ ref('daily_returns') }} p0
        ON p0.ticker = ea.ticker AND p0.trading_day_seq = ea.anchor_seq
    LEFT JOIN {{ ref('daily_returns') }} p7
        ON p7.ticker = ea.ticker AND p7.trading_day_seq = ea.anchor_seq + 7
    LEFT JOIN {{ ref('daily_returns') }} p30
        ON p30.ticker = ea.ticker AND p30.trading_day_seq = ea.anchor_seq + 30

    JOIN spy_prices s0 ON s0.spy_seq = ea.anchor_seq
    LEFT JOIN spy_prices s7 ON s7.spy_seq = ea.anchor_seq + 7
    LEFT JOIN spy_prices s30 ON s30.spy_seq = ea.anchor_seq + 30

    WHERE ea.has_sufficient_history = TRUE
      AND p0.close_price IS NOT NULL
      AND s0.spy_close IS NOT NULL
),

with_car AS (
    SELECT
        ep.ticker,
        ep.quarter_id,
        ep.earnings_date,
        ep.surprise_pct,
        ep.surprise_label,
        ep.stock_d0,
        be.beta,
        be.alpha,
        be.beta_quality,
        ROUND(( ((ep.stock_d7  / ep.stock_d0) - 1)
                - (be.beta * ((ep.spy_d7  / ep.spy_d0) - 1) + be.alpha * 7)
              )::NUMERIC * 100, 4) AS car_7d,
        ROUND(( ((ep.stock_d30 / ep.stock_d0) - 1)
                - (be.beta * ((ep.spy_d30 / ep.spy_d0) - 1) + be.alpha * 30)
              )::NUMERIC * 100, 4) AS car_30d
    FROM event_prices ep
    JOIN {{ ref('beta_estimates') }} be
        ON  be.ticker = ep.ticker
        AND be.quarter_id = ep.quarter_id
)

SELECT
    ticker,
    quarter_id,
    earnings_date,
    surprise_pct,
    surprise_label,
    beta_quality,
    car_7d,
    car_30d,
    ABS(car_7d) AS abs_car_7d
FROM with_car
WHERE stock_d0 IS NOT NULL
