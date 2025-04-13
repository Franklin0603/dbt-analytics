{{
 config(
  materialized = 'view',
  schema = 'staging',
  tags = ['tpch', 'staging']
 )
}}

with source as (
  select * from {{ ref('base_tpch__customers') }}
),

final as (
  select
    -- ids
    customer_id,
    nation_id,

    -- text fields
    customer_name,
    customer_address,
    phone_number,
    market_segment,
    comment,

    -- numeric fields
    account_balance,

    -- calculated fields
    case
      when account_balance < 0 then 'negative'
      when account_balance = 0 then 'zero'
      when account_balance > 0 and account_balance < 5000 then 'low'
      when account_balance >= 5000 and account_balance < 10000 then 'medium'
      else 'high'
    end as balance_tier,

    -- flags
    case when account_balance < 0 then 1 else 0 end as has_negative_balance,
    case when account_balance > 0 then 1 else 0 end as has_positive_balance,
    case when account_balance = 0 then 1 else 0 end as has_zero_balance,

    -- metadata
    created_at,
    updated_at,
    current_timestamp as staging_loaded_at

  from source
)

select * from final