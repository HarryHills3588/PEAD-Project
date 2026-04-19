WITH fiscal_periods AS (
    SELECT DISTINCT fiscal_period
    FROM {{  ref('process_fmp_earn')  }}
    WHERE "fiscal_period" IS NOT NULL
)

SELECT 
    ROW_NUMBER() OVER (ORDER BY fiscal_period DESC) AS quarter_id,
    fiscal_period
FROM fiscal_periods