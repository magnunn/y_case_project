{{
  config(
  materialized = 'table',
  unique_key = 'store_number'
  )
}}
SELECT
    cs.store_county,
    SUM(cs.sale_dollars) AS store_total_revenue
FROM
    {{ ref('clean_sales') }} AS cs
GROUP BY
    cs.store_county
HAVING
    store_total_revenue > 100000
ORDER BY
    store_total_revenue DESC
