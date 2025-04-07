{{
    config(
        materialized='view',
        schema='staging',
        tags=['tpch', 'customer', 'postgres', 'staging']
    )
}}

with base_part as (
    select * from {{ ref('base_tpch_partsupp') }}
),

final as (
    select
        partsupp_id,
        part_id,
        supplier_id,
        available_quantity,
        supply_cost,
        
        -- Calculate total value of inventory
        available_quantity * supply_cost as inventory_value,
        
        comment,
        current_timestamp as loaded_at
    from base_part
)

select * from final