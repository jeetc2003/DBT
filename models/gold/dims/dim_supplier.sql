WITH source AS (

    SELECT *
    FROM {{ ref('transform_product') }}

),

deduplicated AS (

    SELECT *
    FROM (
        SELECT
            supplier_id,
            ROW_NUMBER() OVER (
                PARTITION BY supplier_id
                ORDER BY supplier_id
            ) as rn
        FROM source
        WHERE supplier_id IS NOT NULL
    )
    WHERE rn = 1

),

final AS (

    SELECT

        -- surrogate key
        ROW_NUMBER() OVER (ORDER BY supplier_id) as supplier_key,

        -- business key
        supplier_id

    FROM deduplicated
)

SELECT * FROM final