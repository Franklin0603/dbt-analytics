{{
    config(
        materialized = 'view',
        schema = 'staging',
        tags = ['tpch', 'staging']
    )
}}

with source as (
    select * from {{ ref('base_tpch__part_suppliers') }}
),

final as (
    select
        -- ids
        part_id,
        supplier_id,

        -- amounts
        available_quantity,
        supply_cost,

        -- text fields
        comment,

        -- metadata
        created_at,
        updated_at,
        current_timestamp as staging_loaded_at

    from source
)

select * from final 