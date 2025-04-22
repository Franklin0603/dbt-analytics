{{ config(
    materialized = 'table',
    indexes = [
        {'columns': ['order_id']},
        {'columns': ['customer_id']},
        {'columns': ['order_date']},
        {'columns': ['order_year_month']}
    ],
    tags = ['intermediate', 'orders', 'daily']
) }}

WITH order_items AS (
    SELECT * FROM {{ ref('int_tpch__order_items') }}
),

order_item_summary AS (
    SELECT
        order_id,
        COUNT(*) as total_line_items,
        SUM(quantity) as total_quantity,
        SUM(original_price) as total_original_price,
        SUM(discounted_price) as total_discounted_price,
        SUM(final_price) as total_final_price,
        AVG(discount_percentage) as avg_discount_percentage,
        AVG(tax_rate) as avg_tax_rate,
        MIN(ship_date) as first_ship_date,
        MAX(receipt_date) as last_receipt_date,
        SUM(CASE WHEN is_fulfilled_successfully THEN 1 ELSE 0 END)::FLOAT / 
            COUNT(*) as fulfillment_rate,
        SUM(CASE WHEN delivery_status = 'Delayed' THEN 1 ELSE 0 END)::FLOAT / 
            COUNT(*) as delay_rate,
        MAX(delay_days) as max_delay_days,
        AVG(transit_days) as avg_transit_days
    FROM order_items
    GROUP BY order_id
),

orders AS (
    SELECT * FROM {{ ref('stg_tpch__orders') }}
),

final AS (
    SELECT
        -- Order identifiers
        o.order_id,
        o.customer_id,
        
        -- Date dimensions
        o.order_date,
        DATE_TRUNC('month', o.order_date)::DATE as order_year_month,
        DATE_TRUNC('quarter', o.order_date)::DATE as order_year_quarter,
        DATE_TRUNC('year', o.order_date)::DATE as order_year,
        EXTRACT(DOW FROM o.order_date) as order_day_of_week,
        EXTRACT(MONTH FROM o.order_date) as order_month,
        EXTRACT(QUARTER FROM o.order_date) as order_quarter,
        
        -- Order details
        o.order_status,
        o.order_priority,
        
        -- Order items summary
        s.total_line_items,
        s.total_quantity,
        
        -- Financial metrics
        s.total_original_price,
        s.total_discounted_price,
        s.total_final_price,
        s.avg_discount_percentage,
        s.avg_tax_rate,
        
        -- Calculated financial metrics
        (s.total_original_price - s.total_discounted_price) as total_discount_amount,
        (s.total_final_price - s.total_discounted_price) as total_tax_amount,
        CASE 
            WHEN s.total_original_price > 0 
            THEN (s.total_original_price - s.total_final_price) / s.total_original_price 
            ELSE 0 
        END as total_savings_rate,
        
        -- Shipping metrics and dates
        s.first_ship_date,
        s.last_receipt_date,
        (s.first_ship_date::date - o.order_date::date) as days_to_first_shipment,
        (s.last_receipt_date::date - o.order_date::date) as total_fulfillment_days,
        s.avg_transit_days,
        
        -- Date-based flags
        CASE 
            WHEN (s.first_ship_date::date - o.order_date::date) <= 1 THEN true 
            ELSE false 
        END as is_same_day_shipping,
        
        CASE 
            WHEN (s.first_ship_date::date - o.order_date::date) <= 2 THEN true 
            ELSE false 
        END as is_next_day_shipping,
        
        CASE 
            WHEN EXTRACT(DOW FROM o.order_date) IN (0, 6) THEN true 
            ELSE false 
        END as is_weekend_order,
        
        CASE 
            WHEN s.first_ship_date IS NULL THEN 'Not Shipped'
            WHEN s.last_receipt_date IS NULL THEN 'In Transit'
            WHEN (s.last_receipt_date::date - s.first_ship_date::date) <= s.avg_transit_days THEN 'On Time'
            ELSE 'Delayed'
        END as delivery_status,
        
        -- Performance indicators
        s.fulfillment_rate,
        s.delay_rate,
        s.max_delay_days,
        
        -- Status flags
        CASE 
            WHEN o.order_status = 'F' AND s.fulfillment_rate = 1 THEN true
            ELSE false 
        END as is_fully_fulfilled,
        
        CASE 
            WHEN s.delay_rate = 0 THEN true
            ELSE false 
        END as is_on_time,
        
        CASE 
            WHEN o.order_priority LIKE '%URGENT%' 
                OR o.order_priority LIKE '%HIGH%' THEN true
            ELSE false 
        END as is_high_priority,
        
        -- Timestamps and age calculations
        o.created_at,
        o.updated_at,
        current_timestamp as processed_at,
        EXTRACT(day FROM (current_timestamp - o.created_at)) as days_since_creation,
        EXTRACT(day FROM (current_timestamp - o.updated_at)) as days_since_last_update

    FROM orders o
    LEFT JOIN order_item_summary s 
        ON o.order_id = s.order_id
)

SELECT * FROM final 