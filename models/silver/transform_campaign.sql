WITH source AS (

    SELECT * 
    FROM {{ source('bronze', 'campaign_data') }}

),

cleaned AS (
 -- generic cleaning

    SELECT
        campaign_id,

        {{clean_text('campaign_name')}} as campaign_name,
        {{clean_text('channel')}} as channel,

        -- dates
        try_to_date(start_ts) as start_date,
        try_to_date(end_ts) as end_date,
        try_to_date(last_modified_date) as last_modified_date,

        -- clean budget (remove $, commas, spaces)
        TRY_TO_DECIMAL(
            REGEXP_REPLACE(budget, '[^0-9.]', '')
        ) as budget,

        total_revenue as revenue,
        total_cost as cost,

        {{clean_text('target_audience')}} as target_audience

    FROM source
),

enriched AS (
-- business transformations

    SELECT
        campaign_id,
        campaign_name,
        channel,
        last_modified_date,
        start_date,
        end_date,

        -- CAMPAIGN DURATION
        DATEDIFF(day, start_date, end_date) as campaign_duration_days,

        -- AUDIENCE SEGMENTATION
        CASE
            WHEN LOWER(target_audience) LIKE '%youth%' THEN 'Youth'
            WHEN LOWER(target_audience) LIKE '%adult%' THEN 'Adult'
            WHEN LOWER(target_audience) LIKE '%senior%' THEN 'Senior'
            ELSE 'General'
        END as audience_segment,

        budget,
        revenue,
        cost,

        -- ROI CALCULATION (VALIDATED)
        (revenue - cost) / NULLIF(cost, 0) as expected_roi

    FROM cleaned
),

deduplicated AS (
-- remove duplicates (keep latest)

    SELECT *
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (
                PARTITION BY campaign_id 
                ORDER BY end_date DESC
            ) as rn
        FROM enriched
    )
    WHERE rn = 1
),

transformed AS (

    SELECT
        campaign_id,
        campaign_name,
        channel,
        start_date,
        end_date,
        campaign_duration_days,
        audience_segment,
        budget,
        revenue,
        cost,
        expected_roi

    FROM deduplicated
)

SELECT * FROM transformed