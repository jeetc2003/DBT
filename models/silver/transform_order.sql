{{ config(materialized='tables') }}

WITH source AS (

    SELECT * 
    FROM {{ source('bronze', 'order_data') }}

),

flattened AS (
-- we need to flatten as we have a list of order items that we have to flatten to get details about individual item per order_id

    SELECT
        s.*,
        f.value AS item


    FROM source s,
    LATERAL FLATTEN(input => PARSE_JSON(s.ORDER_ITEMS_ARRAY)) f,
     

),

cleaned AS (
-- here we get all the fields that is needed for our transformations
    SELECT
        order_id,
        customer_id,
        store_id,
        employee_id,
        campaign_id,
        order_status,

        try_to_date(order_date) as order_date,
        try_to_date(shipping_date) as shipping_date,
        try_to_date(delivery_date) as delivery_date,
        try_to_date(estimated_delivery_date) as estimated_delivery_date,

        -- EXTRACT FROM JSON
        item:value:product_id::string as product_id,
        item:value:quantity::int as quantity,
        item:value:unit_price::float as unit_price,
        item:value:cost_price::float as cost_price,
        item:value:discount_amount::float as discount_amount,

        shipping_cost,
        tax_amount

    FROM flattened
),

aggregated AS (
-- order-level aggregation

    SELECT
        order_id,

        COUNT(product_id) as total_items,
        SUM(quantity) as total_quantity,

        SUM(quantity * unit_price) as total_amount,
        SUM(quantity * cost_price) as total_cost,
        SUM(discount_amount) as total_discount

    FROM cleaned
    GROUP BY order_id
),

transformed AS (
-- final transformations

    SELECT
        c.order_id,
        c.customer_id,
        c.store_id,
        c.employee_id,
        c.campaign_id,

        c.order_date,
        c.shipping_date,
        c.delivery_date,
        c.estimated_delivery_date,

        a.total_items,
        a.total_quantity,
        a.total_amount,
        a.total_cost,
        a.total_discount,

        c.shipping_cost,
        c.tax_amount,

        -- PROFIT CALCULATION
        (a.total_amount 
            - a.total_cost 
            - a.total_discount 
            - c.shipping_cost 
            - c.tax_amount) as profit_amount,

        (a.total_amount 
            - a.total_cost 
            - a.total_discount 
            - c.shipping_cost 
            - c.tax_amount) / NULLIF(a.total_amount, 0) * 100 
            as profit_margin_percent,

        -- TIME OF DAY - CANT DO THIS COZ I REMOVED TIME PART FROM DATES WHILE RAW DARA TRANSFORMATIONS IN SNOWFLAKE. SORRY!!!
        -- CASE
        --     WHEN EXTRACT(HOUR FROM c.order_date) BETWEEN 5 AND 11 THEN 'Morning'
        --     WHEN EXTRACT(HOUR FROM c.order_date) BETWEEN 12 AND 16 THEN 'Afternoon'
        --     WHEN EXTRACT(HOUR FROM c.order_date) BETWEEN 17 AND 21 THEN 'Evening'
        --     ELSE 'Night'
        -- END as order_time_of_day,

        -- DATE FEATURES
        EXTRACT(WEEK FROM c.order_date) as order_week,
        EXTRACT(MONTH FROM c.order_date) as order_month,
        EXTRACT(QUARTER FROM c.order_date) as order_quarter,
        EXTRACT(YEAR FROM c.order_date) as order_year,

        -- SHIPPING METRICS
        DATEDIFF(day, c.order_date, c.shipping_date) as processing_days,
        DATEDIFF(day, c.shipping_date, c.delivery_date) as shipping_days,

        -- DELIVERY STATUS
        CASE
            WHEN c.delivery_date IS NOT NULL 
                 AND c.delivery_date <= c.estimated_delivery_date 
                 THEN 'On Time'

            WHEN c.delivery_date IS NOT NULL 
                 AND c.delivery_date > c.estimated_delivery_date 
                 THEN 'Delayed'

            WHEN c.delivery_date IS NULL 
                 AND CURRENT_DATE > c.estimated_delivery_date 
                 THEN 'Potentially Delayed'

            ELSE 'In Transit'
        END as delivery_status

    FROM cleaned c
    JOIN aggregated a 
        ON c.order_id = a.order_id
)

SELECT * FROM transformed