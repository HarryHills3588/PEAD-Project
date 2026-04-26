{{
    config(
        unique_key=['ticker', 'quarter_id']
    )
}}

WITH events AS (
    SELECT
        pw.ticker,
        pw.quarter_id,
        pw.earnings_date,
        pw.surprise_pct,
        pw.surprise_label,
        pw.car_7d,
        pw.car_30d,
        pw.abs_car_7d,
        pw.beta_quality,
        se.sector,

        CASE
            WHEN pw.ticker IN (
                'TSLA','HOOD','COIN','PLTR','SOFI','AMD','NVDA',
                'NFLX','DIS','SNAP','RBLX','ROKU','ZM','DOCU'
            ) THEN 'RETAIL'
            WHEN pw.ticker IN (
                'JPM','V','UNH','COST','ABBV','XOM','BA',
                'GE','GS','BAC','FDX','GM','DAL'
            ) THEN 'INSTITUTIONAL'
            ELSE 'MIXED'
        END AS investor_type
    FROM {{ ref('price_windows') }} pw
    LEFT JOIN {{ ref('stocks') }} st ON st.ticker = pw.ticker
    LEFT JOIN {{ ref('sectors') }} se ON se.sector_id = st.sector_id
    WHERE UPPER(pw.surprise_label) IN ('BEAT', 'MISS')
),

magnitude_tiles AS (
    SELECT
        ticker,
        quarter_id,
        NTILE(3) OVER (
            PARTITION BY UPPER(surprise_label)
            ORDER BY ABS(surprise_pct)
        ) AS mag_tile
    FROM events
),

with_buckets AS (
    SELECT
        e.*,
        CASE mt.mag_tile
            WHEN 1 THEN 'SMALL'
            WHEN 2 THEN 'MEDIUM'
            WHEN 3 THEN 'LARGE'
            ELSE 'SMALL'
        END AS magnitude_bucket
    FROM events e
    JOIN magnitude_tiles mt
        ON mt.ticker = e.ticker
        AND mt.quarter_id = e.quarter_id
)

SELECT
    ticker,
    quarter_id,
    earnings_date,
    surprise_pct,
    UPPER(surprise_label) AS surprise_label,
    magnitude_bucket,
    sector,
    investor_type,
    beta_quality,
    car_7d,
    car_30d,
    abs_car_7d
FROM with_buckets
