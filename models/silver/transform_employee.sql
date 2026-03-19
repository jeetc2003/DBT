WITH source AS (

    SELECT * 
    FROM {{ source('bronze', 'employee_data') }}

),

cleaned AS (
 -- generic cleaning

    SELECT
        employee_id,

        {{clean_text('first_name')}} as first_name,
        {{clean_text('last_name')}} as last_name,

        {{trans_email('email')}} as email,
        {{keep_num('phone')}} as phone,

        {{clean_text('role')}} as role,
        {{clean_text('department')}} as department,

        try_to_date(hire_date) as hire_date,

        sales_target,
        current_sales

    FROM source
),

enriched AS (
-- business transformations

    SELECT
        employee_id,

        -- FULL NAME
        first_name || ' ' || last_name as full_name,

        email,
        phone,

        -- TENURE
        DATEDIFF(year, hire_date, CURRENT_DATE) as tenure_years,

        -- ROLE STANDARDIZATION
        CASE
            WHEN LOWER(role) LIKE '%associate%' THEN 'Associate'
            WHEN LOWER(role) LIKE '%senior manager%' THEN 'Senior Manager'
            WHEN LOWER(role) LIKE '%manager%' THEN 'Manager'
            ELSE role
        END as standardized_role,

        department,

        sales_target,
        current_sales,

        -- TARGET ACHIEVEMENT
        (current_sales / NULLIF(sales_target, 0)) * 100 
            as target_achievement_percentage

    FROM cleaned
),

orders_agg AS (
-- aggregate orders per employee

    SELECT
        employee_id,

        COUNT(DISTINCT order_id) as orders_processed,
        SUM(total_amount) as total_sales_amount

    FROM {{ ref('transform_order') }}
    GROUP BY employee_id
),

transformed AS (

    SELECT
        e.employee_id,
        e.full_name,
        e.email,
        e.phone,
        e.tenure_years,
        e.standardized_role,
        e.department,

        e.sales_target,
        e.current_sales,
        e.target_achievement_percentage,

        -- PERFORMANCE METRICS
        o.orders_processed,
        o.total_sales_amount

    FROM enriched e
    LEFT JOIN orders_agg o
        ON e.employee_id = o.employee_id
)

SELECT * FROM transformed