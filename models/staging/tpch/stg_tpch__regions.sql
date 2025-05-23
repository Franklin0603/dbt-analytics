{{
    config(
        materialized = 'view',
        schema = 'staging',
        tags = ['tpch', 'staging']
    )
}}

with source as (
    select * from {{ ref('base_tpch__regions') }}
),

final as (
    select
        -- ids
        region_id,

        -- text fields
        region_name,
        comment,

        -- metadata
        created_at,
        updated_at,
        current_timestamp as staging_loaded_at

    from source
)

select * from final 