{{
    config(
        materialized='view',
        tags=['tpch', 'intermediate', 'order_summary']
    )
}}

with order_items as (
    select * from {{ ref('int_tpch__order_items') }}
),

orders as (
    select * from {{ ref('stg_tpch__orders') }}
),

-- Aggregate orders items to order level
order_summary as (
    select 
        -- Order identifiers 
        i.order_id,
        i.customer_id,

        -- Order attributes
        i.order_date,
        i.delivery_status,
        o.order_priority, 

        -- Date parts 
        EXTRACT(YEAR FROM i.order_date) as order_year,
        EXTRACT(QUARTER FROM i.order_date) as order_quarter,
        EXTRACT(MONTH FROM i.order_date) as order_month,

        -- Order status 
        i.is_fulfilled_successfully as is_fulfilled,

        -- Aggregate metrics 
        count(i.order_item_id) as item_count,
        count(distinct i.part_id) as unique_part_count,
        count(distinct i.supplier_id) as supplier_count,

        -- Financial summaries 
        sum(i.quantity) as total_quantity,
        sum(i.original_price) as total_extended_price,
        sum(i.discounted_price) as total_discounted_price,
        sum(i.final_price) as total_final_price,
        sum(i.final_price) / nullif(sum(i.quantity), 0) as average_item_price,

        -- Discounts analysis
        sum(i.original_price - i.discounted_price) as total_discount_amount,
        sum(i.original_price - i.discounted_price) / nullif(sum(i.original_price), 0) as discount_percentage,
        
        -- Tax analysis
        sum(i.final_price - i.discounted_price) as total_tax_amount,
        sum(i.final_price - i.discounted_price) / nullif(sum(i.discounted_price), 0) as tax_percentage,
        
        -- Shipping analysis
        min(i.ship_date) as first_ship_date,
        max(i.ship_date) as last_ship_date,
        count(case when i.delivery_status = 'On Time' then 1 end) as on_time_item_count,
        count(case when i.delivery_status = 'On Time' then 1 end)::float / nullif(count(i.order_item_id), 0) as on_time_shipping_rate,
        
        -- Metadata
        current_timestamp as dbt_updated_at
        
    from 
        order_items i
    inner join orders o
        on i.order_id = o.order_id
    group by
        1, 2, 3, 4, 5, 6, 7, 8, 9
)

select * from order_summary
