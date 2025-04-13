{% macro test_metric_threshold(model, column_name, metric_sql, min_value=None, max_value=None) %}
    WITH metric_calculation AS (
        SELECT {{ metric_sql }} AS metric_value
        FROM {{ model }}
    )
    SELECT *
    FROM metric_calculation
    WHERE {% if min_value is not none %}metric_value < {{ min_value }}{% endif %}
    {% if min_value is not none and max_value is not none %}OR{% endif %}
    {% if max_value is not none %}metric_value > {{ max_value }}{% endif %}
{% endmacro %}

{% macro test_metric_change(model, column_name, compare_model, threshold_percent, group_by_columns=None) %}
    WITH current_metrics AS (
        SELECT 
            {% if group_by_columns %}{{ group_by_columns }},{% endif %}
            AVG({{ column_name }}) as current_value
        FROM {{ model }}
        {% if group_by_columns %}GROUP BY {{ group_by_columns }}{% endif %}
    ),
    previous_metrics AS (
        SELECT 
            {% if group_by_columns %}{{ group_by_columns }},{% endif %}
            AVG({{ column_name }}) as previous_value
        FROM {{ compare_model }}
        {% if group_by_columns %}GROUP BY {{ group_by_columns }}{% endif %}
    )
    SELECT 
        c.*,
        p.previous_value,
        ABS((c.current_value - p.previous_value) / NULLIF(p.previous_value, 0)) as change_percent
    FROM current_metrics c
    JOIN previous_metrics p
    {% if group_by_columns %}
        ON {% for column in group_by_columns.split(',') %}
            c.{{ column.strip() }} = p.{{ column.strip() }}
            {% if not loop.last %}AND{% endif %}
        {% endfor %}
    {% else %}
        ON 1=1
    {% endif %}
    WHERE ABS((c.current_value - p.previous_value) / NULLIF(p.previous_value, 0)) > {{ threshold_percent }}
{% endmacro %}

{% macro test_statistical_significance(model, column_name, comparison_value, confidence_level=0.95) %}
    WITH sample_stats AS (
        SELECT
            AVG({{ column_name }}) as sample_mean,
            STDDEV({{ column_name }}) as sample_stddev,
            COUNT(*) as sample_size
        FROM {{ model }}
    )
    SELECT 
        *,
        -- Z-score for two-tailed test at given confidence level
        ABS(sample_mean - {{ comparison_value }}) / 
        (sample_stddev / SQRT(sample_size)) as z_score,
        -- Critical value for 95% confidence is approximately 1.96
        CASE 
            WHEN {{ confidence_level }} = 0.95 THEN 1.96
            WHEN {{ confidence_level }} = 0.99 THEN 2.576
            ELSE 1.645 -- 90% confidence
        END as critical_value
    FROM sample_stats
    WHERE ABS(sample_mean - {{ comparison_value }}) / 
          (sample_stddev / SQRT(sample_size)) > 
          CASE 
              WHEN {{ confidence_level }} = 0.95 THEN 1.96
              WHEN {{ confidence_level }} = 0.99 THEN 2.576
              ELSE 1.645
          END
{% endmacro %} 