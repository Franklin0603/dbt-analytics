{{
    config(
        materialized = 'view',
        schema = 'staging',
        tags = ['tpch', 'staging']
    )
}}

with source as (

    select * from {{ ref('base_tpch__line_items') }}

),

final as (

    select
        -- ids
        order_id,
        part_id,
        supplier_id,
        line_number,

        -- amounts
        quantity,
        extended_price,
        discount,
        tax,

        -- calculated amounts
        extended_price * (1 - discount) as discounted_price,
        extended_price * (1 - discount) * (1 + tax) as final_price,

        -- dates
        ship_date,
        commit_date,
        receipt_date,

        -- flags
        return_flag,
        line_status,

        -- text
        ship_instructions,
        ship_mode,
        comment,

        -- metadata
        created_at,
        updated_at,
        current_timestamp as staging_loaded_at

    from source

)

select * from final 