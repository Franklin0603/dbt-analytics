{{
    config(
        materialized = 'view',
        schema='staging',
        tags = ['tpch', 'base']
    )
}}

with source as (
    select * from {{ source('tpch', 'lineitem') }}
),

renamed as (
    select
        -- ids
        l_orderkey as order_id,
        l_partkey as part_id,
        l_suppkey as supplier_id,
        l_linenumber as line_number,

        -- amounts
        l_quantity as quantity,
        l_extendedprice as extended_price,
        l_discount as discount,
        l_tax as tax,

        -- dates
        l_shipdate as ship_date,
        l_commitdate as commit_date,
        l_receiptdate as receipt_date,

        -- flags
        l_returnflag as return_flag,
        l_linestatus as line_status,

        -- text
        l_shipinstruct as ship_instructions,
        l_shipmode as ship_mode,
        l_comment as comment,

        -- metadata
        current_timestamp as created_at,
        current_timestamp as updated_at

    from source
)

select * from renamed

{% if is_incremental() %}
where created_at > (select max(created_at) from {{ this }})
{% endif %} 