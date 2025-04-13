{{
    config(
        materialized = 'view',
        schema = 'staging',
        tags = ['tpch', 'staging']
    )
}}

with source as (
    select * from {{ ref('base_tpch__orders') }}
),

final as (
    select
        -- ids
        order_id,
        customer_id,

        -- dates
        order_date,
        date_trunc('month', order_date) as order_month,
        date_trunc('quarter', order_date) as order_quarter,
        date_trunc('year', order_date) as order_year,
        extract(dow from order_date) as order_day_of_week,
        extract(doy from order_date) as order_day_of_year,
        
        -- date flags
        case 
            when extract(dow from order_date) in (0, 6) then true 
            else false 
        end as is_weekend_order,
        
        case 
            when extract(hour from order_date) between 9 and 17 then 'business_hours'
            when extract(hour from order_date) between 18 and 22 then 'evening'
            else 'off_hours'
        end as order_time_category,

        -- status
        order_status,
        case 
            when order_status = 'F' then 'Fulfilled'
            when order_status = 'O' then 'Open'
            when order_status = 'P' then 'Pending'
            else order_status
        end as order_status_description,
        
        case 
            when order_status = 'F' then true
            else false
        end as is_fulfilled,

        -- amounts
        total_price,
        round(total_price * 0.08, 2) as estimated_tax,
        round(total_price * 1.08, 2) as total_price_with_tax,

        -- priority metrics
        order_priority,
        case 
            when order_priority like '%URGENT%' or order_priority like '%HIGH%' then true
            else false
        end as is_high_priority,
        
        case
            when order_priority = '1-URGENT' then 1
            when order_priority = '2-HIGH' then 2
            when order_priority = '3-MEDIUM' then 3
            when order_priority = '4-NOT URGENT' then 4
            when order_priority = '5-LOW' then 5
            else 99
        end as priority_rank,

        -- text fields
        clerk,
        ship_priority,
        comment,

        -- metadata
        created_at,
        updated_at,
        current_timestamp as staging_loaded_at

    from source
)

select * from final 