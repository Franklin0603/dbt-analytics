{{
    config(
        materialized='view',
        tags=['tpch', 'intermediate', 'order_summary']
    )
}}

with order_items as (
    select * from {{ ref('int_tpch_order_items') }}
),

-- Aggregate orders items to order level
order_summary as (
    select 
        -- Order identifiers 
        order_id,
        customer_id,

        -- Order attributes
        order_date,
        order_status,
        order_priority, 

        -- Date parts 
        order_year,
        order_quarter,
        order_month,

        -- Order status 
        is_fulfilled,

        -- Aggregate metrics 
        count(lineitem_id) as item_count,
        count(distinct part_id) as unique_part_count,
        count(distinct supplier_id) as supplier_count,

        -- Financial summaries 
        sum(quantity) as total_quantity,
        sum(extended_price) as total_extended_price,
        sum(discounted_price) as total_discounted_price,
        sum(final_price) as total_final_price,
        sum(final_price) / nullif(sum(quantity), 0) as average_item_price,

        -- Discounts analysis
        sum(extended_price - discounted_price) as total_discount_amount,
        sum(extended_price - discounted_price) / nullif(sum(extended_price), 0) as discount_percentage,
        
        -- Tax analysis
        sum(final_price - discounted_price) as total_tax_amount,
        sum(final_price - discounted_price) / nullif(sum(discounted_price), 0) as tax_percentage,
        
        -- Shipping analysis
        min(ship_date) as first_ship_date,
        max(ship_date)  as last_ship_date,
        count(case when is_shipped_on_time then 1 end) as on_time_item_count,
        count(case when is_shipped_on_time then 1 end) / nullif(count(lineitem_id), 0) as on_time_shipping_rate,
        
        -- Metadata
        current_timestamp as dbt_updated_at
        
    from 
        order_items 
    group by
        1, 2, 3, 4, 5, 6, 7, 8, 9
)

select * from order_summary
