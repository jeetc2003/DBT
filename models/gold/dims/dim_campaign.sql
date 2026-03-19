WITH source AS (

    SELECT *
    FROM {{ ref('transform_campaign') }}

),

deduplicated AS (

    SELECT *
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (
                PARTITION BY campaign_id
                ORDER BY end_date DESC NULLS LAST
            ) as rn
        FROM source
    )
    WHERE rn = 1

),

final AS (

    SELECT

        -- surrogate key
        ROW_NUMBER() OVER (ORDER BY campaign_id) as campaign_key,

        -- business key
        campaign_id,

        -- campaign attributes
        audience_segment,
        budget,
        campaign_duration_days as duration,
        expected_roi as roi,

        -- dates
        start_date,
        end_date

    FROM deduplicated
)

SELECT * FROM final