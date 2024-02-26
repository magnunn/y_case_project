{{
  config(
  materialized = 'table',
  unique_key = 'sale_year_quarter'
  )
}}

WITH sales_per_month_cte AS (
  SELECT
    cs.sale_year_month,
    cs.sale_year_quarter,
    SUM(cs.sale_dollars) AS month_revenue,
    COUNT(cs.invoice_and_item_number) AS month_sales_count
  FROM
    {{ ref('clean_sales') }} AS cs
  GROUP BY
    cs.sale_year_month,
    cs.sale_year_quarter
),

quarterly_sales_cte AS (
  SELECT
    cpmc.sale_year_quarter,
    SUM(cpmc.month_revenue) AS quarter_revenue,
    SUM(cpmc.month_revenue) / 3 AS quarter_average_revenue,
    SUM(cpmc.month_sales_count) AS quarter_sales_count
  FROM
    sales_per_month_cte AS cpmc
  GROUP BY
    cpmc.sale_year_quarter
),

revenue_status_cte AS (
  SELECT
    sm.sale_year_month,
    sm.sale_year_quarter,
    sm.month_revenue,
    CASE 
      WHEN sm.month_revenue > qa.quarter_average_revenue * 1.1 
        THEN '10 % Above Average' 
      ELSE 'Below Average' 
    END AS revenue_status
  FROM
    sales_per_month_cte AS sm
    LEFT JOIN quarterly_sales_cte AS qa 
      ON sm.sale_year_quarter = qa.sale_year_quarter
)

SELECT
  qs.sale_year_quarter,
  qs.quarter_revenue AS year_quarter_revenue,
  qs.quarter_revenue / 3 AS quarter_average_revenue,
  qs.quarter_sales_count AS year_quarter_sales_count,
  STRING_AGG(rs.sale_year_month, ', ') AS month_above_average_revenue
FROM
  quarterly_sales_cte AS qs
  LEFT JOIN revenue_status_cte AS rs 
    ON qs.sale_year_quarter = rs.sale_year_quarter
    AND rs.revenue_status = '10 % Above Average'
GROUP BY
  qs.sale_year_quarter, qs.quarter_revenue, qs.quarter_sales_count
ORDER BY
  qs.sale_year_quarter
