WITH deduplicated AS (
    SELECT DISTINCT ON (ticker, fiscal_period) *
    FROM {{  source('raw', 'earnings')  }}
)
SELECT
    ticker::varchar(10),
    fiscal_period::varchar(7),         
    revenue::numeric(20, 2),           
    earnings_per_share::numeric(10, 4),
    estimated_earnings_per_share::numeric(10, 4),
    eps_surprise::varchar(10),        
    net_income::numeric(20, 2),
    gross_profit::numeric(20, 2),
    operating_income::numeric(20, 2),
    weighted_average_shares::numeric::bigint,  
    weighted_average_shares_diluted::numeric::bigint,
    cash_and_equivalents::numeric(20, 2),
    total_debt::numeric(20, 2),
    total_assets::numeric(20, 2),
    total_liabilities::numeric(20, 2),
    shareholders_equity::numeric(20, 2),
    net_cash_flow_from_operations::numeric(20, 2),
    capital_expenditure::numeric(20, 2),
    net_cash_flow_from_investing::numeric(20, 2),
    net_cash_flow_from_financing::numeric(20, 2),
    change_in_cash_and_equivalents::numeric(20, 2),
    free_cash_flow::numeric(20, 2),
    revenue_chg::numeric(10, 6),                     
    net_income_chg::numeric(10, 6),
    operating_income_chg::numeric(10, 6),
    gross_profit_chg::numeric(10, 6),
    free_cash_flow_chg::numeric(10, 6)
FROM deduplicated