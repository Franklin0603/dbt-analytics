{% test assert_date_in_range(model, column_name, min_date, max_date) %}

with validation as (
    select
        {{ column_name }} as date_field
    from {{ model }}
    where {{ column_name }}::date < '{{ min_date }}'::date 
       or {{ column_name }}::date > '{{ max_date }}'::date
)

select *
from validation

{% endtest %}