WITH source AS (

    SELECT *
    FROM {{ ref('transform_product') }}

),

deduplicated AS (

    SELECT *
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (
                PARTITION BY product_id
                ORDER BY file_date DESC NULLS LAST
            ) as rn
        FROM source
    )
    WHERE rn = 1

),

final AS (

    SELECT

        -- SURROGATE KEY
        ROW_NUMBER() OVER (ORDER BY product_id) as product_key,

        -- BUSINESS KEY
        product_id,

        -- CORE ATTRIBUTES
        brand,
        category,
        subcategory,
        product_line,

        -- PRODUCT DETAILS
        

        -- PRICING
        unit_price,
        cost_price,

        -- SUPPLIER
        supplier_id

    FROM deduplicated
)

SELECT * FROM final