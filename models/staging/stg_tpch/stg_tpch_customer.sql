{{
    config(
        materialized='view',
        schema='staging',
        tags=['tpch', 'customer', 'postgres', 'staging']
    )
}}

with source_customer as (
    select * from {{ ref('base_tpch_customer') }}
),
final as (
    select
        customer_id,
        customer_name,
        customer_address,
        nation_id,
        phone_number,
        -- Parse area code from phone number (assuming format like '##-###-###-####')
        split_part(phone_number, '-', 1) as phone_area_code,
        account_balance,

        -- Add derived fields 
        case 
            when account_balance < 0 then 'negative'
            when account_balance = 0 then 'zero'
            when account_balance > 0 and account_balance < 5000 then 'low'
            when account_balance >= 5000 and account_balance < 1000 then 'medium'
            else 'high'
        end as balance_tier,
        market_segment,
        current_timestamp as loaded_at
    from source_customer
)
select * from final

stg_tpch_customer