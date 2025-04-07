{{ config(
    materialized='view',
    tags=['tpch', 'intermediate', 'orders']
) }}

with orders as (
    select * from {{ ref('stg_tpch_orders') }}
),

line_items as (
    select * from {{ ref('stg_tpch_lineitem') }}
),

parts as (
    select * from {{ ref('stg_tpch_part')}}
),

suppliers as (
    select * from {{ ref('stg_tpch_supplier')}}
),

-- join orders with line items and enrich with part and supplier data

order_items as (

    select 
        -- Order and line item keys
        line_items.lineitem_id,
        line_items.order_id,
        orders.customer_id,
        line_items.part_id,
        line_items.supplier_id,
        
        -- Orders information
        orders.order_status_name as order_status,
        orders.order_priority,

         -- Part and supplier information
        parts.part_name,
        parts.manufacturer,
        parts.brand,
        suppliers.supplier_name,
        suppliers.nation_id as supplier_nation_id,
        
        -- Line item details
        line_items.quantity,
        line_items.discount,
        line_items.tax,
        
        -- Calculated fields
        line_items.extended_price,
        line_items.discounted_price,
        line_items.final_price,
        
        -- Shipping information
        line_items.ship_date,
        line_items.ship_mode,
        
        -- Check if item shipped on time
        line_items.is_shipped_on_time,
        
        -- Date parts
        orders.order_date,
        orders.order_year,
        orders.order_month,
        orders.order_quarter,
        
        -- Order status flags
        orders.is_fulfilled,
        
        -- Metadata
        current_timestamp as dbt_updated_at

    from line_items 

    inner join orders
        on line_items.order_id = orders.order_id

    left join parts 
        on line_items.part_id = parts.part_id 

    left join suppliers 
        on line_items.supplier_id = suppliers.supplier_id


)

select * from order_items

-- delivery_metrics as (
--     select
--         order_id,
--         line_number,
--         ship_date,
--         receipt_date,
--         -- Calculate delivery delays
--        (ship_date - commit_date) AS ship_delay,
--        (ship_date - receipt_date) AS transit_time,
--         case
--             when ship_date > commit_date then 'LATE'
--             when ship_date = commit_date then 'ON TIME'
--             else 'EARLY'
--         end as delivery_status
--     from order_items
-- ),

-- price_metrics as (
--     select
--         order_id,
--         line_number,
--         extended_price,
--         discount,
--         tax,
--          -- Calculate various price components
--         round(extended_price * discount, 2) as discount_amount,
--         round(extended_price * (1 - discount), 2) as discounted_price,
--         round(extended_price * (1 - discount) * tax, 2) as tax_amount,
--         round(extended_price * (1 - discount) * (1 + tax), 2) as final_price
--     from order_items
-- ),

-- final as (
--     select

--          -- Order and line item details
--         i.order_id,
--         i.line_number,
--         o.order_date,
--         o.order_status,
--         i.ship_mode,
--         o.customer_id,

--         -- Part and supplier details
--         i.part_id,
--         p.part_name,
--         p.manufacturer,
--         i.supplier_id,
        
--         -- Quantities and base prices
--         i.quantity,
--         i.extended_price as base_price,
        
--         -- Price calculations from price_metrics
--         pm.discount_amount,
--         pm.discounted_price,
--         pm.tax_amount,
--         pm.final_price,
        
--         -- Delivery metrics
--         i.ship_date,
--         i.commit_date,
--         i.receipt_date,
--         dm.ship_delay,
--         dm.transit_time,
--         dm.delivery_status,

--         -- Calculate margins
--         round(pm.final_price - (i.quantity * p.retail_price), 2) as gross_margin,
--         round((pm.final_price - (i.quantity * p.retail_price)) / pm.final_price * 100, 2) as margin_percentage
        

--     from order_items i
--     inner join orders o 
--         on i.order_id = o.order_id
--     inner join parts p 
--         on i.part_id = p.part_id
--     inner join price_metrics pm 
--         on i.order_id = pm.order_id 
--         and i.line_number = pm.line_number
--     inner join delivery_metrics dm 
--         on i.order_id = dm.order_id 
--         and i.line_number = dm.line_number
-- ) 

-- select * from final