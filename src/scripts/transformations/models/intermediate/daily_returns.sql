{{
    config(
        unique_key=['ticker', 'price_date']
    )
}}

WITH base AS (
    SELECT
        ticker,
        "date"      AS price_date,
        "close"     AS close_price,
        LAG("close") OVER (
            PARTITION BY ticker
            ORDER BY "date"
        ) AS prev_close
    FROM {{ ref('prices') }}
    WHERE "close" IS NOT NULL
      AND "close" > 0
)

SELECT
    ticker,
    price_date,
    close_price,

    CASE
        WHEN prev_close IS NOT NULL AND prev_close > 0
        THEN LN(close_price / prev_close)
        ELSE NULL
    END AS log_return,

    ROW_NUMBER() OVER (
        PARTITION BY ticker
        ORDER BY price_date
    ) AS trading_day_seq,

    CASE
        WHEN prev_close IS NOT NULL AND prev_close > 0
             AND ABS(LN(close_price / prev_close)) > 0.5
        THEN TRUE
        ELSE FALSE
    END AS is_suspect_return

FROM base
