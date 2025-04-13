{% macro test_referential_integrity(model, column_name, reference_model, reference_column_name) %}
    WITH parent AS (
        SELECT DISTINCT {{ reference_column_name }} as id
        FROM {{ reference_model }}
        WHERE {{ reference_column_name }} IS NOT NULL
    ),
    child AS (
        SELECT DISTINCT {{ column_name }} as id
        FROM {{ model }}
        WHERE {{ column_name }} IS NOT NULL
    )
    SELECT 
        c.id,
        COUNT(*) as occurrence_count
    FROM child c
    LEFT JOIN parent p ON c.id = p.id
    WHERE p.id IS NULL
    GROUP BY c.id
{% endmacro %}

{% macro test_one_to_many(model, one_side_col, many_side_model, many_side_col, partition_by=None) %}
    WITH many_side AS (
        SELECT 
            {{ many_side_col }} as child_key,
            {% if partition_by %}{{ partition_by }} as partition_key,{% endif %}
            COUNT(*) as child_count
        FROM {{ many_side_model }}
        GROUP BY 
            {{ many_side_col }}
            {% if partition_by %}, {{ partition_by }}{% endif %}
    ),
    one_side AS (
        SELECT DISTINCT 
            {{ one_side_col }} as parent_key
            {% if partition_by %}, {{ partition_by }} as partition_key{% endif %}
        FROM {{ model }}
    )
    SELECT 
        o.parent_key,
        {% if partition_by %}o.partition_key,{% endif %}
        m.child_count
    FROM one_side o
    LEFT JOIN many_side m ON 
        o.parent_key = m.child_key
        {% if partition_by %}AND o.partition_key = m.partition_key{% endif %}
    WHERE m.child_count > 1 OR m.child_count IS NULL
{% endmacro %}

{% macro test_cardinality(model, column_name, expected_cardinality='one_to_one') %}
    WITH value_counts AS (
        SELECT 
            {{ column_name }},
            COUNT(*) as occurrence_count
        FROM {{ model }}
        GROUP BY {{ column_name }}
    )
    SELECT *
    FROM value_counts
    WHERE 
        {% if expected_cardinality == 'one_to_one' %}
            occurrence_count > 1
        {% elif expected_cardinality == 'one_to_many' %}
            occurrence_count = 0
        {% elif expected_cardinality == 'zero_to_one' %}
            occurrence_count > 1
        {% else %}
            FALSE
        {% endif %}
{% endmacro %}

{% macro test_relationship_cycles(model, column_list, max_depth=10) %}
    WITH RECURSIVE relationship_path AS (
        -- Base case: Start with all relationships
        SELECT 
            {{ column_list | join(', ') }},
            1 as depth,
            ARRAY[{{ column_list[0] }}] as path
        FROM {{ model }}
        
        UNION ALL
        
        -- Recursive case: Join back to find next level
        SELECT 
            m.{{ column_list | join(', m.') }},
            r.depth + 1,
            r.path || m.{{ column_list[0] }}
        FROM relationship_path r
        JOIN {{ model }} m ON r.{{ column_list[-1] }} = m.{{ column_list[0] }}
        WHERE r.depth < {{ max_depth }}
            AND NOT m.{{ column_list[0] }} = ANY(r.path)
    )
    SELECT *
    FROM relationship_path
    WHERE {{ column_list[0] }} = ANY(path[2:])
{% endmacro %} 