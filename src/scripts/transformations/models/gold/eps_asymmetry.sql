SELECT
surprise_label,
magnitude_bucket,
sector,
investor_type,
beta_quality,
earnings_date,
COUNT(*) AS n_events,
ROUND(AVG(car_7d)::NUMERIC, 2) AS avg_car_7d,
ROUND(AVG(abs_car_7d)::NUMERIC, 2) AS avg_abs_car_7d,
ROUND(AVG(car_30d)::NUMERIC, 2) AS avg_car_30d,
ROUND(STDDEV(car_7d)::NUMERIC, 2) AS stddev_car_7d
FROM {{  ref('mart_asymmetry_events')  }}
WHERE beta_quality IN ('GOOD', 'WEAK')
GROUP BY surprise_label, magnitude_bucket, sector, investor_type, beta_quality, earnings_date
ORDER BY magnitude_bucket, surprise_label