SELECT
investor_type,
surprise_label,
ticker,
sector,
magnitude_bucket,
beta_quality,
earnings_date,
COUNT(*) AS n_events,
ROUND(AVG(abs_car_7d)::NUMERIC, 2) AS avg_abs_car_7d,
ROUND(AVG(car_7d)::NUMERIC, 2) AS avg_car_7d,
ROUND(AVG(car_30d)::NUMERIC, 2) AS avg_car_30d
FROM {{  ref('mart_asymmetry_events')  }}
WHERE beta_quality IN ('GOOD', 'WEAK')
AND investor_type IN ('RETAIL', 'INSTITUTIONAL')
GROUP BY investor_type, surprise_label, sector, magnitude_bucket, beta_quality, ticker, earnings_date
ORDER BY investor_type, surprise_label