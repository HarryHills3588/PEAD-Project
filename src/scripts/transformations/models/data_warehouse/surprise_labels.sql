WITH surprise_labels as (
    SELECT DISTINCT surprise_label
    FROM {{  ref('process_fmp_earn')  }}
    WHERE surprise_label IS NOT NULL
)

SELECT
    ROW_NUMBER() OVER (ORDER BY surprise_label DESC) AS surp_label_id,
    surprise_label
FROM surprise_labels