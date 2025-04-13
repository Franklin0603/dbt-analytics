{{
    config(
        materialized = 'view',
        schema='staging',
        tags = ['tpch', 'base']
    )
}}

with source as (
    select * from {{ source('tpch', 'part') }}
),

renamed as (
    select
        -- ids
        p_partkey as part_id,

        -- text fields
        p_name as part_name,
        p_mfgr as manufacturer,
        p_brand as brand,
        p_type as type,
        p_container as container,

        -- amounts
        p_size as size,
        p_retailprice as retail_price,

        -- text fields
        p_comment as comment,

        -- metadata
        current_timestamp as created_at,
        current_timestamp as updated_at

    from source
)

select * from renamed

{% if is_incremental() %}
where created_at > (select max(created_at) from {{ this }})
{% endif %} 