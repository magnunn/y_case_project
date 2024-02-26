{{
  config(
    materialized = 'incremental',
    unique_key = 'invoice_and_item_number'
    )
}}
SELECT
    sales.invoice_and_item_number,
    sales.date AS sale_date,
    EXTRACT(YEAR FROM sales.date) AS sale_year,
    CONCAT(
        EXTRACT(YEAR FROM sales.date),
        '-',
        EXTRACT(MONTH FROM sales.date)
    ) AS sale_year_month,
    CONCAT(
        EXTRACT(YEAR FROM sales.date),
        '-',
        EXTRACT(QUARTER FROM sales.date)
    ) AS sale_year_quarter,
    sales.store_number,
    sales.store_name,
    sales.address AS store_address,
    sales.city AS store_city,
    {{ replace_and_safe_cast('sales.zip_code', '.0', '', 'INT') }} AS zip_code,
    sales.store_location,
    sales.county_number AS store_county_number,
    sales.county AS store_county,
    {{ replace_and_safe_cast('sales.category', '.0', '', 'INT') }} AS item_category,
    sales.category_name AS item_category_name,
    {{ replace_and_safe_cast('sales.vendor_number', '.0', '', 'INT') }} AS vendor_number,
    sales.vendor_name,
    sales.item_number,
    sales.item_description,
    sales.pack AS item_pack_size,
    sales.bottle_volume_ml,
    sales.state_bottle_cost,
    sales.state_bottle_retail,
    sales.bottles_sold,
    ROUND(sales.sale_dollars, 2) AS sale_dollars,
    sales.volume_sold_liters,
    sales.volume_sold_gallons,
    sales.ingestion_datetime
FROM
    {{ ref('raw_sales') }} AS sales
{% if is_incremental() %}
    WHERE
        ingestion_datetime >= (SELECT MAX(ingestion_datetime) FROM {{ this }})
{% endif %}
