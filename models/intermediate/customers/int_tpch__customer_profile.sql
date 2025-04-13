{{
    config(
        materialized='table',
        tags=['tpch', 'intermediate', 'customer']
    )
}}

with customers as (
    select * from {{ ref("stg_tpch__customers") }}
),

nations as (
    select * from {{ ref("stg_tpch__nations")}}
),

regions as (
    select * from {{ ref("stg_tpch__regions")}}
),

-- Combine customer data with geographic information
final as (
    select 
        -- Customer identifiers and primary attributes
        c.customer_id,
        c.customer_name,
        c.account_balance,
        c.market_segment,

        -- Geographic hierarchy
        c.nation_id,
        n.nation_name,
        n.region_id,
        r.region_name,

        -- Classification based on account balance
        case
            when c.account_balance < 0 then 'negative'
            when c.account_balance = 0 then 'zero'
            when c.account_balance > 0 and c.account_balance < 5000 then 'low'
            when c.account_balance >= 5000 and c.account_balance < 10000 then 'medium'
            else 'high'
        end as balance_tier,
        
        -- Metadata
        current_timestamp as dbt_updated_at

    from 
        customers c 
    
    -- join to geographic dimension 
    left join nations n 
        on c.nation_id = n.nation_id
    
    left join regions r 
        on n.region_id = r.region_id
)

select * from final