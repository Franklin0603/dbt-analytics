{{
    config(
        materialized='view',
        schema='staging',
        tags=['tpch', 'nation', 'postgres', 'staging']
    )
}}

with source as (
    select * from {{ source('tpch', 'nation') }}
),

renamed as (
    select
        n_nationkey as nation_id,
        n_name as nation_name,
        n_regionkey as region_id,
        n_comment as comment
    from source
),

final as (
    select
        nation_id,
        nation_name,
        region_id,
        comment,
        current_timestamp as loaded_at
    from renamed
)

select * from final