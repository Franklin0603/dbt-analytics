{{ config(
    materialized = 'table',
    indexes = [
        {'columns': ['order_id']},
        {'columns': ['part_id']},
        {'columns': ['supplier_id']}
    ],
    tags = ['intermediate', 'orders', 'daily']
) }}

{%- set status_values = ['F', 'O', 'P'] -%} {# Fulfilled, Open, Pending #}

WITH line_items AS (
    SELECT * FROM {{ ref('stg_tpch__line_items') }}
),

parts AS (
    SELECT * FROM {{ ref('stg_tpch__parts') }}
),

suppliers AS (
    SELECT * FROM {{ ref('stg_tpch__suppliers') }}
),

orders AS (
    SELECT * FROM {{ ref('stg_tpch__orders') }}
),

enriched_items AS (
    SELECT
        -- Surrogate key
        {{ generate_surrogate_key(['l.order_id', 'l.line_number']) }} as order_item_id,
        
        -- Foreign keys
        l.order_id,
        l.part_id,
        l.supplier_id,
        o.customer_id,
        
        -- Item details
        l.line_number,
        l.quantity,
        l.extended_price as original_price,
        
        -- Part details
        p.part_name,
        p.manufacturer,
        p.brand,
        p.type as part_type,
        p.size as part_size,
        p.container,
        
        -- Supplier details
        s.supplier_name,
        s.nation_id as supplier_nation_id,
        
        -- Pricing calculations
        l.discount as discount_percentage,
        l.extended_price * (1 - l.discount) as discounted_price,
        l.tax as tax_rate,
        l.extended_price * (1 - l.discount) * (1 + l.tax) as final_price,
        
        -- Shipping details
        l.ship_date,
        l.commit_date,
        l.receipt_date,
        l.ship_mode,
        
        -- Shipping status
        CASE 
            WHEN l.receipt_date IS NULL THEN 'In Transit'
            WHEN l.receipt_date <= l.commit_date THEN 'On Time'
            ELSE 'Delayed'
        END as delivery_status,
        
        -- Shipping metrics
        (l.ship_date::date - o.order_date::date) as days_to_ship,
        (l.receipt_date::date - l.ship_date::date) as transit_days,
        (l.receipt_date::date - o.order_date::date) as total_fulfillment_days,
        
        -- Return flag
        l.return_flag,
        
        -- Line status
        l.line_status,
        
        -- Timestamps and metadata
        o.order_date,
        l.created_at,
        l.updated_at,
        current_timestamp as processed_at

    FROM line_items l
    INNER JOIN orders o 
        ON l.order_id = o.order_id
    INNER JOIN parts p 
        ON l.part_id = p.part_id
    INNER JOIN suppliers s 
        ON l.supplier_id = s.supplier_id
),

final AS (
    SELECT 
        *,
        -- Additional derived metrics
        CASE
            WHEN delivery_status = 'Delayed' THEN 
                (receipt_date::date - commit_date::date)
            ELSE 0
        END as delay_days,
        
        CASE
            WHEN final_price > original_price THEN 
                (final_price - original_price) / original_price
            ELSE 0
        END as price_increase_ratio,
        
        CASE
            WHEN quantity > 0 THEN 
                final_price / quantity
            ELSE 0
        END as unit_price,
        
        -- Fulfillment flags
        CASE 
            WHEN transit_days <= 5 THEN true 
            ELSE false 
        END as is_fast_shipping,
        
        CASE 
            WHEN delivery_status = 'On Time' 
                AND return_flag = 'N' 
                AND line_status = 'F' 
            THEN true 
            ELSE false 
        END as is_fulfilled_successfully
        
    FROM enriched_items
)

SELECT * FROM final