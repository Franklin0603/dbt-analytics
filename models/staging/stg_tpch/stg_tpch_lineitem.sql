{{
    config(
        materialized='view',
        schema='staging',
        tags=['tpch', 'linenumber', 'postgres', 'staging']
    )
}}

with source as (
    select * from {{ ref('base_tpch_lineitem') }}
),

final as (
    select
        lineitem_id,
        order_id,
        part_id,
        supplier_id,
        line_number,
        quantity,
        extended_price,
        discount,
        tax,
        
        -- Add calculated fields
        extended_price * (1 - discount) as discounted_price,
        extended_price * (1 - discount) * (1 + tax) as final_price,
        
        return_flag,
        line_status,
        ship_date,
        commit_date,
        receipt_date,

        -- Derived fields 
        case 
            when ship_date <= commit_date then true 
            else false 
        end as is_shipped_on_time,

        ship_instructions,
        ship_mode,
        comment,
        
        current_timestamp as loaded_at
    from source
)

select * from final
