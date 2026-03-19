{% macro clean_text(col)%}
-- To get string with First letter caps and other small.
    trim(initcap({{col}}))
{% endmacro %}

{% macro to_upper(col)%}
-- To get uppercase string of col. Used for location
    trim(upper({{col}}))
{% endmacro %}

{% macro keep_num(col)%}
-- used to clean zip codes and make them in order
-- Can be used for phone_numbers as well
       regexp_replace({{col}}, '[^0-9]', '') 
{% endmacro %}


{% macro trans_email(col) %}
-- to check emails
    LOWER(TRIM({{ col }}))
{% endmacro %}


