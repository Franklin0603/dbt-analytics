with base_region as (
    select * from {{ ref('base_tpch_region') }}
),

final as (
    select
        region_id,
        region_name,
        comment,
        current_timestamp as loaded_at
    from base_region
)

select * from final