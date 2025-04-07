{{
    config(
        materialized='view',
        schema='staging',
        tags=['tpch', 'order', 'postgres', 'staging']
    )
}}

with base_orders as (
    select * from {{ ref('base_tpch_orders') }}
),

final as (
    select
        order_id,
        customer_id,
        order_status,
        total_price,
        order_date,
        
        -- Add date parts for easier querying and analysis
        extract(year from order_date) as order_year,
        extract(month from order_date) as order_month,
        extract(quarter from order_date) as order_quarter,

        order_priority,
        clerk,
        ship_priority,

        -- Add derived fields
        case
            when order_status = 'P' then 'Pending'
            when order_status = 'O' then 'Open'
            when order_status = 'F' then 'Fulfilled'
            else 'Unknown'
        end as order_status_name,

        -- Add flags
        case when order_status = 'F' then true else false end as is_fulfilled,
        
        comment,
        
        current_timestamp as loaded_at
    from base_orders
)

select * from final