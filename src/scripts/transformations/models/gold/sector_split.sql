SELECT
sector,
surprise_label,
COUNT(*) AS n_events,
ROUND(AVG(car_7d)::NUMERIC, 2) AS avg_car_7d,
ROUND(AVG(abs_car_7d)::NUMERIC, 2) AS avg_abs_car_7d
FROM {{  ref('mart_asymmetry_events')  }}
WHERE beta_quality IN ('GOOD', 'WEAK')
GROUP BY sector, surprise_label
HAVING COUNT(*) >= 5
ORDER BY sector, surprise_label