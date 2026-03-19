WITH source AS (

    SELECT *
    FROM {{ ref('transform_store') }}

),

deduplicated AS (

    SELECT *
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (
                PARTITION BY store_id
                order by store_id
            ) as rn
        FROM source
    )
    WHERE rn = 1

),

final AS (

    SELECT

        -- SURROGATE KEY
        ROW_NUMBER() OVER (ORDER BY store_id) as store_key,

        -- BUSINESS KEY
        store_id,

        -- CORE ATTRIBUTES
        store_name,
        full_address as address,
        region,
        store_type,

        -- STORE DETAILS
        
        size_category

    FROM deduplicated
)

SELECT * FROM final