WITH source AS (

    SELECT * 
    FROM {{ source('bronze', 'store_data') }}

),

cleaned AS (
 -- generic cleaning

    SELECT
        store_id,

        {{clean_text('store_name')}} as store_name,

        store_type,
        region,

        is_active,

        current_sales,
        sales_target,
        monthly_rent,

        employee_count,
        size_sq_ft,

        try_to_date(opening_date) as opening_date,

        -- address fields
        {{clean_text('city')}} as city,
        {{clean_text('state')}} as state,
        {{clean_text('country')}} as country,
        {{clean_text('street')}} as street,
        {{keep_num('zip_code')}} as zip_code

    FROM source
),

enriched AS (
-- business transformations

    SELECT
        store_id,
        store_name,
        store_type,
        region,
        is_active,

        current_sales,
        sales_target,
        monthly_rent,

        employee_count,
        size_sq_ft,

        -- SIZE CATEGORY
        CASE
            WHEN size_sq_ft < 5000 THEN 'Small'
            WHEN size_sq_ft BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Large'
        END as size_category,

        -- STORE AGE
        DATEDIFF(year, opening_date, CURRENT_DATE) as store_age_years,

        -- ADDRESS STANDARDIZATION
        COALESCE(street,'') || ', ' ||
        COALESCE(city,'') || ', ' ||
        COALESCE(state,'') || ' - ' ||
        COALESCE(zip_code,'') || ', ' ||
        COALESCE(country,'') as full_address,

        -- PERFORMANCE METRICS
        (current_sales / NULLIF(sales_target, 0)) * 100 
            as sales_target_achievement,

        (current_sales / NULLIF(size_sq_ft, 0)) 
            as revenue_per_sq_ft,

        (current_sales / NULLIF(employee_count, 0)) 
            as employee_efficiency

    FROM cleaned
),

transformed AS (

    SELECT
        *,

        -- PERFORMANCE FLAG
        CASE
            WHEN sales_target_achievement < 90 THEN TRUE
            ELSE FALSE
        END as is_underperforming

    FROM enriched
)

SELECT * FROM transformed