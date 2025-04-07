with base_region as (
    select * from {{ ref('base_tpch_supplier') }}
),

final as (
    select
        supplier_id,
        supplier_name,
        supplier_address,
        nation_id,
        phone_number,
        account_balance,
        comment,
        current_timestamp as loaded_at
    from base_region
)

select * from final