{{
    config(
        materialized='table',
        unique_key='order_key',
        sort='order_date',
        dist='customer_key',
        tags=['core', 'orders']
    )
}}

with orders as (
    
    select * from {{ ref('stg_tpch_orders') }}

),

customers as (
    
    select * from {{ ref('dim_customers') }}

),

line_items as (
    
    select * from {{ ref('stg_tpch_lineitem') }}

),

order_items_summary as (
    
    select
        order_id,
        count(*) as item_count,
        sum(quantity) as total_quantity,
        sum(extended_price) as total_extended_price,
        sum(extended_price * (1 - discount)) as total_discounted_price,
        sum(extended_price * (1 - discount) * (1 + tax)) as total_price_with_tax,
        min(ship_date) as first_ship_date,
        max(ship_date) as last_ship_date
    from line_items
    group by 1

),

final as (
    
    select
        -- Surrogate key
        {{ dbt_utils.generate_surrogate_key(['orders.order_id']) }} as order_key,
        
        -- Natural key
        orders.order_id,
        
        -- Foreign keys
        {{ dbt_utils.generate_surrogate_key(['orders.customer_id']) }} as customer_key,
        customers.customer_id,
        
        -- Order dates
        orders.order_date,
        
        -- Order attributes
        orders.order_status,
        orders.order_priority,
        orders.ship_priority,
        orders.clerk,
        
        -- Order metrics
        orders.total_price as order_total_price,
        ois.item_count,
        ois.total_quantity,
        ois.total_extended_price,
        ois.total_discounted_price,
        ois.total_price_with_tax,
        
        -- Shipping metrics
        ois.first_ship_date,
        ois.last_ship_date,
        
        -- Calculation of ship time
        extract('day' from age(ois.first_ship_date, orders.order_date))::integer as days_to_first_shipment,
        extract('day' from age(ois.last_ship_date, orders.order_date))::integer as days_to_last_shipment,
        
        -- Additional flags
        case 
            when orders.order_status = 'F' then true
            else false
        end as is_fulfilled,
        
        -- Date dimensions
        extract('year' from orders.order_date) as order_year,
        extract('quarter' from orders.order_date) as order_quarter,
        extract('month' from orders.order_date) as order_month,
        
        -- Metadata fields
        orders.comment as order_comment,
        current_timestamp as dbt_updated_at
        
    from orders
    
    left join customers
        on orders.customer_id = customers.customer_id
        
    left join order_items_summary as ois
        on orders.order_id = ois.order_id

)

select * from final