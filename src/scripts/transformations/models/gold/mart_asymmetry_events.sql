{{
    config(
        unique_key=['ticker', 'quarter_id']
    )
}}

WITH all_events AS (
    SELECT
        sb.ticker,
        sb.quarter_id,
        sb.earnings_date,
        sb.surprise_pct,
        sb.surprise_label,
        sb.magnitude_bucket,
        sb.sector,
        sb.investor_type,
        sb.beta_quality,
        sb.car_7d,
        sb.car_30d,
        sb.abs_car_7d
    FROM {{ ref('surprise_buckets') }} sb
),

with_pairs AS (
    SELECT
        ae.*,
        mp.beat_quarter_id,
        mp.beat_surprise_pct AS pair_beat_surprise_pct,
        mp.beat_car_7d AS pair_beat_car_7d,
        mp.beat_car_30d AS pair_beat_car_30d,
        mp.asymmetry_7d,
        mp.asymmetry_30d,
        mp.asymmetry_ratio_7d,
        mp.asymmetry_ratio_30d,
        mp.magnitude_diff AS pair_magnitude_diff,
        mp.is_clean_pair,
        CASE
            WHEN mp.miss_quarter_id IS NOT NULL THEN TRUE
            ELSE FALSE
        END AS has_matched_pair
    FROM all_events ae
    LEFT JOIN {{ ref('matched_pairs') }} mp
        ON  mp.ticker = ae.ticker
        AND mp.miss_quarter_id = ae.quarter_id
),

with_dimensions AS (
    SELECT
        wp.*,
        wp.quarter_id AS qtr_dim_id,
        st.name AS company_name,
        st.exchange_id,
        st.location_id,
        sl.surp_label_id
    FROM with_pairs wp
    LEFT JOIN {{ ref('stocks') }} st
        ON st.ticker = wp.ticker
    LEFT JOIN {{ ref('surprise_labels') }} sl
        ON sl.surprise_label = wp.surprise_label
),

with_zscore AS (
    SELECT
        *,
        ROUND((
            car_7d - AVG(car_7d) OVER (PARTITION BY quarter_id)
        ) / NULLIF(
            STDDEV(car_7d) OVER (PARTITION BY quarter_id), 0
        )::NUMERIC, 4) AS car_7d_zscore
    FROM with_dimensions
)

SELECT
    ticker,
    company_name,
    quarter_id,
    qtr_dim_id,
    earnings_date,
    exchange_id,
    location_id,
    surp_label_id,
    sector,
    investor_type,
    surprise_pct,
    surprise_label,
    magnitude_bucket,
    beta_quality,
    car_7d,
    car_7d_zscore,
    car_30d,
    abs_car_7d,
    has_matched_pair,
    beat_quarter_id,
    pair_beat_surprise_pct,
    pair_beat_car_7d,
    pair_beat_car_30d,
    asymmetry_7d,
    asymmetry_30d,
    asymmetry_ratio_7d,
    asymmetry_ratio_30d,
    pair_magnitude_diff,
    is_clean_pair,

    CASE
        WHEN surprise_label   = 'MISS'
         AND has_matched_pair = TRUE
         AND asymmetry_7d     > 0
        THEN TRUE ELSE FALSE
    END AS confirms_h1_asymmetry,

    CASE
        WHEN surprise_label     = 'MISS'
         AND investor_type      = 'RETAIL'
         AND asymmetry_ratio_7d > 1.5
        THEN TRUE ELSE FALSE
    END AS confirms_h2_retail_bias

FROM with_zscore
ORDER BY earnings_date DESC, ticker
