{% macro generate_date_spine(start_date, end_date) %}

{%- set sql -%}
WITH date_spine AS (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('" ~ start_date ~ "' as date)",
        end_date="cast('" ~ end_date ~ "' as date)"
    ) }}
),
enriched_dates AS (
    SELECT
        -- Date keys
        CAST(TO_CHAR(date_day, 'YYYYMMDD') AS VARCHAR) AS date_id,
        date_day AS date,
        
        -- Calendar hierarchies
        EXTRACT(YEAR FROM date_day) AS year,
        EXTRACT(QUARTER FROM date_day) AS quarter,
        EXTRACT(MONTH FROM date_day) AS month,
        TO_CHAR(date_day, 'Month') AS month_name,
        EXTRACT(WEEK FROM date_day) AS week,
        EXTRACT(DOW FROM date_day) AS day_of_week,
        TO_CHAR(date_day, 'Day') AS day_name,
        
        -- Flags
        CASE 
            WHEN EXTRACT(DOW FROM date_day) IN (0, 6) THEN TRUE 
            ELSE FALSE 
        END AS is_weekend,
        
        -- Fiscal calendar (assuming fiscal year starts April 1)
        CASE 
            WHEN EXTRACT(MONTH FROM date_day) >= 4 
            THEN EXTRACT(YEAR FROM date_day)
            ELSE EXTRACT(YEAR FROM date_day) - 1
        END AS fiscal_year,
        
        CASE 
            WHEN EXTRACT(MONTH FROM date_day) >= 4 
            THEN CEIL((EXTRACT(MONTH FROM date_day) - 3) / 3)
            ELSE CEIL((EXTRACT(MONTH FROM date_day) + 9) / 3)
        END AS fiscal_quarter,
        
        -- Additional attributes
        CASE 
            WHEN EXTRACT(MONTH FROM date_day) = 1 AND EXTRACT(DAY FROM date_day) = 1 THEN TRUE
            WHEN EXTRACT(MONTH FROM date_day) = 12 AND EXTRACT(DAY FROM date_day) = 25 THEN TRUE
            ELSE FALSE
        END AS is_holiday,
        
        -- Period calculations
        LAST_DAY(date_day) AS last_day_of_month,
        DATE_TRUNC('month', date_day) AS first_day_of_month,
        DATE_TRUNC('quarter', date_day) AS first_day_of_quarter,
        DATE_TRUNC('year', date_day) AS first_day_of_year
    FROM date_spine
)
SELECT * FROM enriched_dates
{%- endset -%}

{% do return(sql) %}
{% endmacro %} 