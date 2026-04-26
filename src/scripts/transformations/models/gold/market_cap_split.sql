SELECT
CASE
    WHEN ticker IN (
        'AAPL','MSFT','NVDA','GOOGL','META','AMZN',
        'TSLA','NFLX','JPM','V','BAC','GS','UNH',
        'COST','XOM','ABBV','PFE'
    ) THEN 'LARGE'
    WHEN ticker IN (
        'AMD','ADBE','INTC','DIS','SBUX','NKE','TGT',
        'UBER','PYPL','FDX','GE','GM','BA','DAL','MRO'
    ) THEN 'MID'
    ELSE 'SMALL'
END AS cap_tier,
surprise_label,
sector,
beta_quality,
earnings_date,
COUNT(*) AS n_events,
ROUND(AVG(abs_car_7d)::NUMERIC, 2) AS avg_abs_car_7d,
ROUND(AVG(car_7d)::NUMERIC, 2) AS avg_car_7d,
ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP
(ORDER BY car_7d)::NUMERIC, 2) AS median_car_7d
FROM {{  ref('mart_asymmetry_events')  }}
WHERE beta_quality IN ('GOOD', 'WEAK')
GROUP BY cap_tier, surprise_label, sector, beta_quality, earnings_date
ORDER BY cap_tier, surprise_label
