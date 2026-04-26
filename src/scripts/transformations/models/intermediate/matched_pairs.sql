{{
    config(
        unique_key=['ticker', 'miss_quarter_id']
    )
}}

WITH beats AS (
    SELECT
        ticker,
        quarter_id AS beat_quarter_id,
        surprise_pct AS beat_surprise_pct,
        ABS(surprise_pct) AS beat_magnitude,
        magnitude_bucket AS beat_bucket,
        car_7d AS beat_car_7d,
        car_30d AS beat_car_30d,
        earnings_date AS beat_date
    FROM {{ ref('surprise_buckets') }}
    WHERE surprise_label = 'BEAT'
),

misses AS (
    SELECT
        ticker,
        quarter_id AS miss_quarter_id,
        ABS(surprise_pct) AS miss_magnitude,
        magnitude_bucket AS miss_bucket,
        car_7d AS miss_car_7d,
        car_30d AS miss_car_30d,
        earnings_date AS miss_date
    FROM {{ ref('surprise_buckets') }}
    WHERE surprise_label = 'MISS'
),

candidate_pairs AS (
    SELECT
        m.ticker,
        m.miss_quarter_id,
        m.miss_magnitude,
        m.miss_bucket,
        m.miss_car_7d,
        m.miss_car_30d,
        b.beat_quarter_id,
        b.beat_surprise_pct,
        b.beat_magnitude,
        b.beat_bucket,
        b.beat_car_7d,
        b.beat_car_30d,
        ABS(m.miss_magnitude - b.beat_magnitude) AS magnitude_diff,
        ROW_NUMBER() OVER (
            PARTITION BY m.ticker, m.miss_quarter_id
            ORDER BY
                ABS(m.miss_magnitude - b.beat_magnitude) ASC,
                b.beat_date DESC
        ) AS match_rank

    FROM misses m
    JOIN beats b
        ON  b.ticker  = m.ticker
        AND b.beat_quarter_id != m.miss_quarter_id
        AND b.beat_date != m.miss_date
        AND ABS(m.miss_magnitude - b.beat_magnitude) <= 3.0
)

SELECT
    ticker,
    miss_quarter_id,
    beat_quarter_id,
    ROUND(beat_surprise_pct::NUMERIC, 2) AS beat_surprise_pct,
    ROUND(beat_car_7d::NUMERIC, 4) AS beat_car_7d,
    ROUND(beat_car_30d::NUMERIC, 4) AS beat_car_30d,
    ROUND((ABS(miss_car_7d)  - ABS(beat_car_7d))::NUMERIC,  4) AS asymmetry_7d,
    ROUND((ABS(miss_car_30d) - ABS(beat_car_30d))::NUMERIC, 4) AS asymmetry_30d,
    ROUND(
        CASE WHEN ABS(beat_car_7d) > 0
             THEN ABS(miss_car_7d) / ABS(beat_car_7d)
             ELSE NULL
        END::NUMERIC, 4
    ) AS asymmetry_ratio_7d,
    ROUND(
        CASE WHEN ABS(beat_car_30d) > 0
             THEN ABS(miss_car_30d) / ABS(beat_car_30d)
             ELSE NULL
        END::NUMERIC, 4
    ) AS asymmetry_ratio_30d,
    ROUND(magnitude_diff::NUMERIC, 2) AS magnitude_diff,
    CASE
        WHEN miss_bucket = beat_bucket AND magnitude_diff <= 1.5
        THEN TRUE ELSE FALSE
    END AS is_clean_pair
FROM candidate_pairs
WHERE match_rank = 1
