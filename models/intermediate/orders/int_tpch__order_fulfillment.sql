{{ config(
    materialized = 'table',
    indexes = [
        {'columns': ['order_id']},
        {'columns': ['first_shipment_date']},
        {'columns': ['last_shipment_date']},
        {'columns': ['order_year']},
        {'columns': ['order_month']},
        {'columns': ['fulfillment_status']}
    ],
    tags = ['intermediate', 'orders', 'fulfillment', 'daily']
) }}

WITH order_items AS (
    SELECT * FROM {{ ref('int_tpch__order_items') }}
),

order_metrics AS (
    SELECT * FROM {{ ref('int_tpch__order_metrics') }}
),

shipping_modes AS (
    SELECT * FROM {{ ref('shipping_modes') }}
),

fulfillment_status AS (
    SELECT
        order_id,
        
        -- Shipping timeline
        MIN(ship_date) as first_shipment_date,
        MAX(ship_date) as last_shipment_date,
        MIN(commit_date) as earliest_commit_date,
        MAX(commit_date) as latest_commit_date,
        MIN(receipt_date) as first_receipt_date,
        MAX(receipt_date) as last_receipt_date,
        
        -- Shipping modes
        COUNT(DISTINCT ship_mode) as shipping_modes_used,
        STRING_AGG(DISTINCT ship_mode, ', ') as shipping_mode_list,
        
        -- Item counts
        COUNT(*) as total_items,
        SUM(quantity) as total_quantity,
        
        -- Status counts
        SUM(CASE WHEN delivery_status = 'In Transit' THEN 1 ELSE 0 END) as items_in_transit,
        SUM(CASE WHEN delivery_status = 'On Time' THEN 1 ELSE 0 END) as items_on_time,
        SUM(CASE WHEN delivery_status = 'Delayed' THEN 1 ELSE 0 END) as items_delayed,
        
        -- Performance metrics
        AVG(transit_days) as avg_transit_days,
        MAX(transit_days) as max_transit_days,
        AVG(delay_days) as avg_delay_days,
        MAX(delay_days) as max_delay_days
        
    FROM order_items
    GROUP BY order_id
),

final AS (
    SELECT
        -- Order details
        f.order_id,
        m.customer_id,
        m.order_date,
        m.order_status,
        m.order_priority,
        
        -- Date dimensions
        -- DATE_TRUNC('month', m.order_date) as order_year_month,
        -- DATE_TRUNC('quarter', m.order_date) as order_year_quarter,
        -- DATE_TRUNC('year', m.order_date) as order_year,
        EXTRACT(DOW FROM m.order_date) as order_day_of_week,
        EXTRACT(MONTH FROM m.order_date) as order_month,
        EXTRACT(QUARTER FROM m.order_date) as order_quarter,
        EXTRACT(YEAR FROM m.order_date) as order_year,
        
        -- Shipping timeline
        f.first_shipment_date,
        f.last_shipment_date,
        f.earliest_commit_date,
        f.latest_commit_date,
        f.first_receipt_date,
        f.last_receipt_date,
        
        -- Enhanced time calculations
        (f.first_shipment_date::date - m.order_date::date) as days_to_first_ship,
        (f.last_receipt_date::date - f.first_shipment_date::date) as total_transit_days,
        (f.last_receipt_date::date - m.order_date::date) as total_fulfillment_days,
        -- EXTRACT(hour FROM (f.first_shipment_date - m.order_date)) as hours_to_first_ship,
        --EXTRACT(hour FROM (f.last_receipt_date - f.first_shipment_date)) as total_transit_hours,
        
        -- Time-based flags
        CASE 
            WHEN (f.first_shipment_date::date - m.order_date::date) = 0 THEN true 
            ELSE false 
        END as is_same_day_shipping,
        
        CASE 
            WHEN (f.first_shipment_date::date - m.order_date::date) <= 1 THEN true 
            ELSE false 
        END as is_next_day_shipping,
        
        CASE 
            WHEN EXTRACT(DOW FROM m.order_date) IN (0, 6) THEN true 
            ELSE false 
        END as is_weekend_order,
        
        -- Shipping details
        f.shipping_modes_used,
        f.shipping_mode_list,
        
        -- Item counts
        f.total_items,
        f.total_quantity,
        
        -- Status breakdown
        f.items_in_transit,
        f.items_on_time,
        f.items_delayed,
        
        -- Performance metrics
        f.avg_transit_days,
        f.max_transit_days,
        f.avg_delay_days,
        f.max_delay_days,
        
        -- Enhanced delivery metrics
        CASE 
            WHEN f.total_items > 0 THEN 
                f.items_on_time::FLOAT / f.total_items 
            ELSE 0 
        END as on_time_delivery_rate,
        
        CASE 
            WHEN f.total_items > 0 THEN 
                f.items_delayed::FLOAT / f.total_items 
            ELSE 0 
        END as delay_rate,
        
        -- Enhanced status flags
        CASE
            WHEN f.items_in_transit > 0 THEN 'In Progress'
            WHEN f.items_delayed > 0 AND f.avg_delay_days > 5 THEN 'Severely Delayed'
            WHEN f.items_delayed > 0 THEN 'Delayed'
            WHEN f.items_on_time = f.total_items THEN 'Completed On Time'
            ELSE 'Unknown'
        END as fulfillment_status,
        
        CASE 
            WHEN f.items_in_transit = 0 
                AND f.items_delayed = 0 
                AND f.items_on_time = f.total_items 
            THEN true 
            ELSE false 
        END as is_perfectly_fulfilled,
        
        -- Enhanced risk indicators
        CASE
            WHEN f.avg_delay_days > 5 THEN 'High Risk'
            WHEN f.avg_delay_days > 2 THEN 'Medium Risk'
            WHEN f.avg_delay_days > 0 THEN 'Low Risk'
            ELSE 'No Risk'
        END as delivery_risk_level,
        
        -- Age calculations
        -- EXTRACT(day FROM (CURRENT_DATE - m.order_date::date)) as days_since_order,
        -- EXTRACT(day FROM (CURRENT_DATE - COALESCE(f.last_receipt_date::date, CURRENT_DATE))) as days_since_last_receipt,
        
        -- Timestamps
        m.created_at,
        m.updated_at,
        current_timestamp as processed_at

    FROM fulfillment_status f
    INNER JOIN order_metrics m 
        ON f.order_id = m.order_id
)

SELECT * FROM final 