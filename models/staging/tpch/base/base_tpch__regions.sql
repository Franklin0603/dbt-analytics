{{
    config(
        materialized = 'view',
        schema='staging',
        tags = ['tpch', 'base']
    )
}}

with source as (
    select * from {{ source('tpch', 'region') }}
),

renamed as (
    select
        -- ids
        r_regionkey as region_id,

        -- text fields
        r_name as region_name,
        r_comment as comment,

        -- metadata
        current_timestamp as created_at,
        current_timestamp as updated_at

    from source
)

select * from renamed

{% if is_incremental() %}
where created_at > (select max(created_at) from {{ this }})
{% endif %} 