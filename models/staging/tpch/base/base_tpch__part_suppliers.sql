{{
    config(
        materialized = 'view',
        schema='staging',
        tags = ['tpch', 'base']
    )
}}

with source as (
    select * from {{ source('tpch', 'partsupp') }}
),

renamed as (
    select
        -- ids
        ps_partkey as part_id,
        ps_suppkey as supplier_id,

        -- amounts
        ps_availqty as available_quantity,
        ps_supplycost as supply_cost,

        -- text fields
        ps_comment as comment,

        -- metadata
        current_timestamp as created_at,
        current_timestamp as updated_at

    from source
)

select * from renamed

{% if is_incremental() %}
where created_at > (select max(created_at) from {{ this }})
{% endif %} 