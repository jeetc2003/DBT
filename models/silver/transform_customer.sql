


WITH source AS (
    SELECT * 
    FROM {{ source('bronze', 'customer_data') }}
),
cleaned AS (
 -- generic cleaning
    select 
        date_of_file as file_date,
        customer_id,
        {{clean_text('first_name')}} as first_name,
        {{clean_text('last_name')}} as last_name,
        {{trans_email('email')}} as email,
        {{keep_num('phone')}} as phone,
        {{clean_text('occupation')}} as occupation,
        {{to_upper('income_bracket')}} as income_bracket,
        try_to_date((birth_date)) as birth_date,
        try_to_date((registration_date)) as reg_date,
        try_to_date((last_purchase_date)) as last_purchase_date,
        try_to_date((last_modified_date)) as last_modified_date,
        total_purchases,
        total_spend,
        {{clean_text('city')}} as city,
        {{clean_text('state')}} as state,
        {{clean_text('country')}} as country,
        {{clean_text('street')}} as street,
        {{keep_num('zip_code')}} as zip_code

    from source     
),
transformed AS (
-- specific cleaning
    select
        file_date,
        customer_id,
        total_spend,
        total_purchases,
        reg_date,
        last_purchase_date,
        last_modified_date, 
        first_name || ' ' || last_name as full_name,
        datediff(year, birth_date, current_date()) as age,
        case 
            when datediff(year, birth_date, current_date()) between 18 and 35 then 'young'
            when datediff(year, birth_date, current_date()) between 36 and 55 then 'middle-aged'
            else 'senior'
        end  as segment,
        coalesce(street,'') || ', ' || coalesce(city, '') || '-' || coalesce(zip_code, '') || ', ' || coalesce(state, '') || ', ' || coalesce(country, '') AS address,
        email,
        phone

    from cleaned 
)

SELECT * FROM transformed

