WITH source AS (

    SELECT *
    FROM {{ ref('transform_campaign') }}

),

deduplicated AS (

SELECT *
FROM source
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY campaign_id
    ORDER BY last_modified_date DESC
) = 1

),

final AS (

SELECT
    campaign_id,
    campaign_name,

    campaign_type,
    channel,

    description,
    target_audience,

    start_date,
    end_date,

    /* calculate duration */

    DATEDIFF(day,start_date,end_date) AS campaign_duration_days,

    budget,
    total_cost,
    total_revenue,

    /* use staging ROI */

    roi_calculation AS calculated_roi,

    last_modified_date

FROM deduplicated

)

SELECT * FROM final