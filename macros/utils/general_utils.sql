{% macro get_custom_schema(custom_schema_name, node) %}
    {% set default_schema = target.schema %}
    {% if custom_schema_name is none %}
        {{ default_schema }}
    {% else %}
        {{ default_schema }}_{{ custom_schema_name | trim }}
    {% endif %}
{% endmacro %}

{% macro generate_schema_name(custom_schema_name=none, node=none) %}
    {{ get_custom_schema(custom_schema_name, node) }}
{% endmacro %}

{% macro get_tables_by_pattern(schema_pattern, table_pattern) %}
    SELECT 
        schemaname as schema_name,
        tablename as table_name,
        tableowner as table_owner
    FROM pg_tables
    WHERE schemaname ~ '{{ schema_pattern }}'
        AND tablename ~ '{{ table_pattern }}'
{% endmacro %}

{% macro get_column_values(table, column, max_results=100) %}
    SELECT DISTINCT {{ column }}
    FROM {{ table }}
    WHERE {{ column }} IS NOT NULL
    LIMIT {{ max_results }}
{% endmacro %}

{% macro date_range_filter(column, start_date=none, end_date=none) %}
    {% if start_date is not none and end_date is not none %}
        {{ column }} BETWEEN '{{ start_date }}' AND '{{ end_date }}'
    {% elif start_date is not none %}
        {{ column }} >= '{{ start_date }}'
    {% elif end_date is not none %}
        {{ column }} <= '{{ end_date }}'
    {% else %}
        TRUE
    {% endif %}
{% endmacro %}

{% macro generate_comment_header() %}
    {%- set header = '
    -- =========================================================================
    -- Model: ' ~ this.name ~ '
    -- Description: ' ~ model.description ~ '
    -- Created by: ' ~ target.user ~ '
    -- Created at: ' ~ modules.datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S") ~ '
    -- Database: ' ~ target.database ~ '
    -- Schema: ' ~ target.schema ~ '
    -- Dependencies: ' ~ model.refs | join(', ') ~ '
    -- =========================================================================
    ' -%}
    {{ header }}
{% endmacro %}

{% macro except_columns(columns=[]) %}
    {% set cols = adapter.get_columns_in_relation(this) %}
    {% set col_list = [] %}
    {% for col in cols %}
        {% if col.name not in columns %}
            {% do col_list.append(col.name) %}
        {% endif %}
    {% endfor %}
    {{ return(col_list | join(', ')) }}
{% endmacro %} 