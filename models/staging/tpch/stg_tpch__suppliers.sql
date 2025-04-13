{{
    config(
        materialized = 'view',
        schema = 'staging',
        tags = ['tpch', 'staging']
    )
}}

with source as (
    select * from {{ ref('base_tpch__suppliers') }}
),

final as (
    select
        -- ids
        supplier_id,
        nation_id,

        -- text fields
        supplier_name,
        supplier_address,
        phone_number,
        comment,

        -- amounts
        account_balance,

        -- metadata
        created_at,
        updated_at,
        current_timestamp as staging_loaded_at

    from source
)

select * from final 