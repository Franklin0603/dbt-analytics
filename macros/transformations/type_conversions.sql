{% macro safe_cast(field, type) %}
    CASE
        WHEN {{ field }} IS NULL THEN NULL
        WHEN {{ type }} IN ('integer', 'bigint') THEN
            CASE 
                WHEN REGEXP_REPLACE(TRIM({{ field }}), '[^0-9.-]', '', 'g') = '' THEN NULL
                ELSE CAST(REGEXP_REPLACE(TRIM({{ field }}), '[^0-9.-]', '', 'g') AS {{ type }})
            END
        WHEN {{ type }} = 'boolean' THEN
            CASE 
                WHEN LOWER(TRIM({{ field }})) IN ('true', 't', 'yes', 'y', '1') THEN TRUE
                WHEN LOWER(TRIM({{ field }})) IN ('false', 'f', 'no', 'n', '0') THEN FALSE
                ELSE NULL
            END
        WHEN {{ type }} = 'date' THEN
            CASE 
                WHEN {{ field }} ~ '^\d{4}-\d{2}-\d{2}$' THEN CAST({{ field }} AS date)
                WHEN {{ field }} ~ '^\d{8}$' THEN 
                    CAST(SUBSTRING({{ field }}, 1, 4) || '-' || 
                         SUBSTRING({{ field }}, 5, 2) || '-' || 
                         SUBSTRING({{ field }}, 7, 2) AS date)
                ELSE NULL
            END
        ELSE CAST({{ field }} AS {{ type }})
    END
{% endmacro %}

{% macro standardize_timestamp(field, timezone='UTC') %}
    CASE
        WHEN {{ field }} IS NULL THEN NULL
        ELSE (CAST({{ field }} AS timestamp) AT TIME ZONE '{{ timezone }}')
    END
{% endmacro %}

{% macro clean_string(field) %}
    CASE
        WHEN {{ field }} IS NULL THEN NULL
        ELSE REGEXP_REPLACE(
            TRIM(BOTH ' ' FROM {{ field }}),
            '[^\w\s-]',
            '',
            'g'
        )
    END
{% endmacro %}

{% macro normalize_phone(field) %}
    CASE
        WHEN {{ field }} IS NULL THEN NULL
        ELSE REGEXP_REPLACE({{ field }}, '[^0-9]', '', 'g')
    END
{% endmacro %}

{% macro format_currency(amount, decimal_places=2) %}
    ROUND(
        COALESCE(
            CASE
                WHEN {{ amount }} IS NULL THEN NULL
                WHEN TRIM({{ amount }}) ~ '^[0-9.,-]+$' 
                    THEN CAST(REPLACE(REPLACE({{ amount }}, ',', ''), '$', '') AS decimal)
                ELSE NULL
            END,
            0
        ),
        {{ decimal_places }}
    )
{% endmacro %} 