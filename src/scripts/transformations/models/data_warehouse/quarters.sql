{{
    config(
        unique_key='quarter_id'
    )
}}

WITH fiscal_periods AS (
    SELECT DISTINCT fiscal_period,
    created_at
    FROM {{  ref('process_fmp_earn')  }}
    WHERE "fiscal_period" IS NOT NULL
)

SELECT 
    ROW_NUMBER() OVER (ORDER BY fiscal_period DESC) AS quarter_id,
    fiscal_period,
    created_at
FROM fiscal_periods

{% if is_incremental() %}
    WHERE created_at > (SELECT max(created_at) FROM {{ this }})
{% endif %}