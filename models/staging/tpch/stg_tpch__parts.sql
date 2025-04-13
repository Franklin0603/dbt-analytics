{{
    config(
        materialized = 'view',
        schema = 'staging',
        tags = ['tpch', 'staging']
    )
}}

with source as (
    select * from {{ ref('base_tpch__parts') }}
),

final as (
    select
        -- ids
        part_id,

        -- text fields
        part_name,
        manufacturer,
        brand,
        type,
        container,

        -- amounts
        size,
        retail_price,

        -- text fields
        comment,

        -- calculated fields
        case
            when size > 45 then 'LARGE'
            when size > 25 then 'MEDIUM'
            else 'SMALL'
        end as size_category,

        -- metadata
        created_at,
        updated_at,
        current_timestamp as staging_loaded_at

    from source
)

select * from final 