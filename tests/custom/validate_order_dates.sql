{% test validate_order_dates(model, column_name) %}

select
    *
from {{ model }}
where {{ column_name }} > current_date
   or {{ column_name }} < '1990-01-01'

{% endtest %}