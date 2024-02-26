{{
  config(
    materialized = 'incremental',
    unique_key = 'invoice_and_item_number'
    )
}}
SELECT
    sales.invoice_and_item_number,
    sales.date,
    sales.store_number,
    sales.store_name,
    sales.address,
    sales.city,
    sales.zip_code,
    sales.store_location,
    sales.county_number,
    sales.county,
    sales.category,
    sales.category_name,
    sales.vendor_number,
    sales.vendor_name,
    sales.item_number,
    sales.item_description,
    sales.pack,
    sales.bottle_volume_ml,
    sales.state_bottle_cost,
    sales.state_bottle_retail,
    sales.bottles_sold,
    sales.sale_dollars,
    sales.volume_sold_liters,
    sales.volume_sold_gallons,
    CURRENT_DATETIME() AS ingestion_datetime
FROM
    {{ source('bigquery-public-data.iowa_liquor_sales', 'sales') }} AS sales
{% if is_incremental() %}
    WHERE
        date >= (SELECT MAX(date) FROM {{ this }})
{% endif %}
