-- custom test to validate phone number formats in custom data
-- Returns records that don't match the expected format

{% test assert_phone_format(model, column_name) %}

with validation as (
    select
        {{ column_name }} as phone_number
    from {{ model }}
    where {{ column_name }} !~ '^[0-9]{2}-[0-9]{3}-[0-9]{3}-[0-9]{4}$'
)

select *
from validation

{% endtest %}