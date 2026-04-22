{{
    config(
        unique_key='surp_label_id'
    )
}}

WITH surprise_labels as (
    SELECT DISTINCT surprise_label,
    created_at
    FROM {{  ref('process_fmp_earn')  }}
    WHERE surprise_label IS NOT NULL
)

SELECT
    ROW_NUMBER() OVER (ORDER BY surprise_label DESC) AS surp_label_id,
    surprise_label,
    created_at
FROM surprise_labels

{% if is_incremental() %}
    WHERE created_at > (SELECT max(created_at) FROM {{ this }})
{% endif %}