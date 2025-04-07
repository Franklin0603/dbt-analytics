{{
    config(
        materialized = 'ephemeral',
        tags = ['tpch', 'base']
    )
}}

with source as (
    select * from {{ source('tpch', 'supplier') }}
),

renamed as (
    select
        s_suppkey as supplier_id,
        s_name as supplier_name,
        s_address as supplier_address,
        s_nationkey as nation_id,
        s_phone as phone_number,
        s_acctbal as account_balance,
        s_comment as comment
    from source
)

select * from renamed