WITH source AS (

    SELECT *
    FROM {{ ref('transform_customer') }}

),

deduplicated AS (

    SELECT *
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (
                PARTITION BY customer_id
                ORDER BY last_modified_date DESC NULLS LAST
            ) as rn
        FROM source
    )
    WHERE rn = 1

),

final AS (

    SELECT

        -- SURROGATE KEY
        ROW_NUMBER() OVER (ORDER BY customer_id) as customer_key,

        -- BUSINESS KEY
        customer_id,

        -- CORE ATTRIBUTES
        full_name,
        email,
        phone,

        -- DEMOGRAPHIC INFO
        age,
        segment,

        -- ADDRESS
        address,

        -- OPTIONAL (ONLY IF EXISTS)
        reg_date

    FROM deduplicated
)

SELECT * FROM final