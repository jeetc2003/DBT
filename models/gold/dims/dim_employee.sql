WITH source AS (

    SELECT *
    FROM {{ ref('transform_employee') }}

),

deduplicated AS (

    SELECT *
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (
                PARTITION BY employee_id
                ORDER BY tenure_years DESC NULLS LAST
            ) as rn
        FROM source
    )
    WHERE rn = 1

),

final AS (

    SELECT

        -- surrogate key
        ROW_NUMBER() OVER (ORDER BY employee_id) as employee_key,

        -- business key
        employee_id,

        -- core attributes
        full_name,
        standardized_role as role,
        department as work_location,

        -- employee info
        tenure_years,
        email,
        phone,

        -- performance metrics
        orders_processed,
        total_sales_amount,
        target_achievement_percentage

    FROM deduplicated
)

SELECT * FROM final