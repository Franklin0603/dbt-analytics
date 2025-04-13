{{
    config(
        materialized='view',
        schema='staging',
        tags = ['tpch', 'base']
    )
}}

with source as (

    select * from {{ source('tpch', 'customer') }}

),

renamed as (

    select
        -- ids
        c_custkey as customer_id,
        c_nationkey as nation_id,

        -- text fields
        c_name as customer_name,
        c_address as customer_address,
        c_phone as phone_number,
        c_mktsegment as market_segment,
        c_comment as comment,

        -- numeric fields
        c_acctbal as account_balance,

        -- metadata
        current_timestamp as created_at,
        current_timestamp as updated_at

    from source

),

final as (

    select
        customer_id,
        customer_name,
        customer_address,
        nation_id,
        phone_number,
        account_balance,
        market_segment,
        comment,
        created_at,
        updated_at
    from renamed
)

select * from final

{% if is_incremental() %}
where created_at > (select max(created_at) from {{ this }})
{% endif %} 