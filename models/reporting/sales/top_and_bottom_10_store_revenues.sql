{{
  config(
  materialized = 'table',
  unique_key = 'store_number'
  )
}}
WITH rank_store_revenue_cte AS (
    SELECT
        cs.store_number,
        SUM(cs.sale_dollars) AS store_total_revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(cs.sale_dollars) DESC) AS store_revenue_rank
    FROM
        {{ ref('clean_sales') }} AS cs
    GROUP BY
        cs.store_number
)

SELECT
    store_number,
    store_total_revenue,
    store_revenue_rank
FROM
    rank_store_revenue_cte
WHERE
    store_revenue_rank <= 10 
    OR store_revenue_rank > (SELECT COUNT(*) FROM rank_store_revenue_cte) - 10
ORDER BY
    store_revenue_rank
