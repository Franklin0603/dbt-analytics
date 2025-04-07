-- macros/test_helpers.sql

{% macro test_null_proportion(model, column_name, threshold=0.1) %}
/*
    Tests if the proportion of nulls in a column exceeds a threshold
    Example usage:
    {{ test_null_proportion(ref('my_model'), 'my_column', 0.1) }}
*/
with null_count as (
    select 
        count(*) as total_records,
        sum(case when {{ column_name }} is null then 1 else 0 end) as null_records
    from {{ model }}
)

select *
from null_count
where (null_records::float / total_records) > {{ threshold }}
{% endmacro %}

{% macro test_value_distribution(model, column_name, min_distinct_values=10) %}
/*
    Tests if a column has a healthy distribution of values
    Example usage:
    {{ test_value_distribution(ref('my_model'), 'my_column', 10) }}
*/
with value_counts as (
    select 
        count(distinct {{ column_name }}) as distinct_values,
        count(*) as total_records
    from {{ model }}
)

select *
from value_counts
where distinct_values < {{ min_distinct_values }}
  and total_records > {{ min_distinct_values }} * 10
{% endmacro %}

{% macro test_date_range(model, column_name, min_date, max_date) %}
/*
    Tests if dates fall within an expected range
    Example usage:
    {{ test_date_range(ref('my_model'), 'date_column', "'1990-01-01'", "'2025-12-31'") }}
*/
select *
from {{ model }}
where {{ column_name }} < {{ min_date }}
   or {{ column_name }} > {{ max_date }}
{% endmacro %}

{% macro test_referential_integrity(model, column_name, reference_model, reference_column) %}
/*
    Tests referential integrity between tables
    Example usage:
    {{ test_referential_integrity(ref('my_model'), 'foreign_key', ref('parent_model'), 'primary_key') }}
*/
select distinct a.{{ column_name }}
from {{ model }} a
left join {{ reference_model }} b
    on a.{{ column_name }} = b.{{ reference_column }}
where b.{{ reference_column }} is null
  and a.{{ column_name }} is not null
{% endmacro %}