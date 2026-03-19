{{ config(materialized='table',
            schema='DBT.DBT_JCHOUDHARY_SILVER_LAYER' ) }}
WITH source AS (
    SELECT * 
    FROM {{ source('bronze', 'product_data') }}
),
cleaned AS (
 -- generic cleaning
    select 
        date_of_file as file_date,
        product_id,
        {{clean_text('product_name')}} as product_name,
        {{clean_text('brand')}} as brand,
        {{clean_text('category')}} as category,
        {{clean_text('subcategory')}} subcategory,
        {{clean_text('product_line')}} product_line,
        supplier_id,
        is_featured,
        cost_price,
        unit_price,
        reorder_level,
        stock_quantity,
        {{clean_text('color')}} as color,
        {{clean_text('dimensions')}} as dimensions,
        {{clean_text('weight')}} as weight,
        {{clean_text('short_description')}} as short_description,
        {{clean_text('technical_specs')}} as tech_specs,
        CASE 
            WHEN LEFT(TRIM(warranty_period), 1) LIKE '[0-9]' 
                THEN try_to_decimal((substring(TRIM(warranty_period), 1, charindex(' ', TRIM(warranty_period))-1 )), 2,0)
            ELSE 
                0
        END AS warranty_period
        
    from source     
),
transformed AS (
-- specific cleaning
    select
        file_date,
        product_id,
        brand,
        -- full description built
        product_name || ' | ' || short_description || ' | ' || tech_specs as full_description,
        category,
        subcategory,
        product_line,
        -- profit margin percentage calculated
        (unit_price - cost_price)/unit_price * 100 as profit_margin_percent,
        -- created a new col name low_stock to check if stock is sufficient or not
        supplier_id,
        is_featured,
        cost_price,
        unit_price,
        reorder_level,
        stock_quantity,
        CASE
            when stock_quantity < reorder_level then TRUE
            else FALSE
        end as low_stock,
        warranty_period

    from cleaned 
)

SELECT * FROM transformed

