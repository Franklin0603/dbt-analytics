{{
    config(
        materialized = 'table',
        unique_key='customer_key',
        tags=['tpch','core','dimension']
    )
}}

with customer_profile as (
    select * from {{ ref('int_tpch__customer_profile')}}
),

customer_orders as (
    select * from {{ ref('int_tpch__customer_orders') }}
),

customer_segments as (
    select * from {{ ref('int_tpch__customer_segments') }}
),

-- join all customer data and add surrogate key
final as (
    select 
        -- Surrogate key for dimension table
        {{ dbt_utils.generate_surrogate_key(['cp.customer_id']) }} as customer_key,

        -- Natural/business key 
        cp.customer_id,

        -- Customer attributes
        cp.customer_name,
        
        -- Geographic attributes
        cp.nation_id,
        cp.nation_name,
        cp.region_id,
        cp.region_name,
        
        -- Business attributes
        cp.market_segment,
        cp.balance_tier,
        cp.account_balance,

        -- Customer behavior metrics
        coalesce(co.total_orders, 0) as lifetime_orders,
        coalesce(co.orders_last_year, 0) as orders_last_year,
        coalesce(co.orders_last_3_months, 0) as orders_last_3_months,
        coalesce(co.total_revenue, 0) as lifetime_revenue,
        coalesce(co.revenue_last_year, 0) as revenue_last_year,
        coalesce(co.avg_order_value, 0) as avg_order_value,

        -- Date and timespan metrics
        co.first_order_date,
        co.most_recent_order_date,
        co.customer_tenure_days,
        coalesce(co.days_since_last_order, 9999) as days_since_last_order,
        co.avg_days_between_orders,
        
        -- Segmentation
        cs.lifecycle_stage,
        cs.purchase_frequency_segment,
        cs.aov_segment,
        cs.customer_value_tier,
        cs.business_segment,

        -- RFM components
        cs.recency_score,
        cs.frequency_score,
        cs.monetary_score,
        cs.rfm_score,
        cs.rfm_segment,
        
        -- Shipping/fulfillment metrics
        coalesce(co.avg_on_time_shipping_rate, 0) as avg_on_time_shipping_rate,
        coalesce(co.fulfilled_order_ratio, 0) as fulfilled_order_ratio,
        
        -- Additional metadata
        current_timestamp as valid_from,
        null as valid_to,
        true as is_current,
        current_timestamp as dbt_updated_at

    from customer_profile cp 
    
    left join customer_orders co
        on cp.customer_id = co.customer_id 
    
    left join customer_segments cs 
        on cp.customer_id = cs.customer_id
)

select * from final