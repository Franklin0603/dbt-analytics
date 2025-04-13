{% macro generate_surrogate_key(field_list) %}
    {#- Convert field_list to a list if it's a string -#}
    {%- if field_list is string -%}
        {%- set field_list = [field_list] -%}
    {%- endif -%}

    {#- Handle null values and different data types -#}
    {%- set fields = [] -%}
    {%- for field in field_list -%}
        {%- set cleaned_field -%}
            COALESCE(
                CAST(
                    CASE 
                        WHEN {{ field }} IS NULL THEN 'NULL'
                        ELSE CAST({{ field }} AS VARCHAR)
                    END 
                AS VARCHAR
                ), 'NULL'
            )
        {%- endset -%}
        {%- do fields.append(cleaned_field) -%}
    {%- endfor -%}

    {#- Generate hash using MD5 -#}
    MD5({{ fields | join(" || '|' || ") }})
{% endmacro %}

{# Example usage:
    {{ generate_surrogate_key(['customer_id', 'order_date']) }} as order_sk
#} 