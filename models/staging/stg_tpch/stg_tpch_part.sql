{{
    config(
        materialized='view',
        schema='staging',
        tags=['tpch', 'part', 'postgres', 'staging']
    )
}}

with base_part as (
    select * from {{ ref('base_tpch_part') }}
),

final as (
    select
        part_id,
        part_name,
        manufacturer,
        brand,
        type,
        size,
        container,
        retail_price,
        comment,
        current_timestamp as loaded_at
    from base_part
)

select * from final