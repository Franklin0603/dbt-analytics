{{
    config(
        materialized = 'view',
        schema='staging',
        tags = ['tpch', 'base']
    )
}}

with source as (
    select * from {{ source('tpch', 'orders') }}
),

renamed as (
    select
        -- ids
        o_orderkey as order_id,
        o_custkey as customer_id,

        -- dates
        o_orderdate as order_date,

        -- status
        o_orderstatus as order_status,

        -- amounts
        o_totalprice as total_price,

        -- text fields
        o_orderpriority as order_priority,
        o_clerk as clerk,
        o_shippriority as ship_priority,
        o_comment as comment,

        -- metadata
        current_timestamp as created_at,
        current_timestamp as updated_at

    from source
)

select * from renamed

{% if is_incremental() %}
where created_at > (select max(created_at) from {{ this }})
{% endif %} 