WITH date_spine AS (

    SELECT 
        DATEADD(day, seq4(), '2018-01-01') as full_date
    FROM TABLE(GENERATOR(ROWCOUNT => 3000))  -- ~8 years

),

final AS (

    SELECT

        -- SURROGATE KEY
        TO_NUMBER(TO_CHAR(full_date, 'YYYYMMDD')) as date_key,

        -- CORE DATE
        full_date,
        
        -- DATE PARTS
        YEAR(full_date) as year,
        QUARTER(full_date) as quarter,
        MONTH(full_date) as month,
        WEEK(full_date) as week,
        DAYOFWEEK(full_date) as day_of_week,

        -- HOLIDAY FLAG (SIMPLE LOGIC)
        CASE 
            WHEN TO_CHAR(full_date, 'MM-DD') IN (
                '01-01',  -- New Year
                '07-04',  -- Independence Day
                '12-25'   -- Christmas
            ) THEN TRUE
            ELSE FALSE
        END as is_us_holiday,

        -- SEASON
        CASE
            WHEN MONTH(full_date) IN (12,1,2) THEN 'Winter'
            WHEN MONTH(full_date) IN (3,4,5) THEN 'Spring'
            WHEN MONTH(full_date) IN (6,7,8) THEN 'Summer'
            ELSE 'Fall'
        END as season

    FROM date_spine
)

SELECT * FROM final