{{
    config(
        materialized = 'table',
        tags = ['tpch', 'intermediate', 'customer']
    )
}}

with customer_profile as (
    
    select * from {{ ref('int_tpch__customer_profile') }}

),

customer_orders as (
    
    select * from {{ ref('int_tpch__customer_orders') }}

),

-- Calculate RFM components 
rfm_components as (
    select 
        customer_id,

        -- Recency - days since last order
        days_since_last_order,

        -- Recency score (5=most recent, 1=least recent)
        case
            when days_since_last_order <= 30 then 5
            when days_since_last_order <= 90 then 4
            when days_since_last_order <= 180 then 3
            when days_since_last_order <= 365 then 2
            else 1
        end as recency_score,

        -- Frequency - number of orders in last year 
        orders_last_year,

        -- Frequency score (5=most frequent, 1=least frequent)
        case
            when orders_last_year >= 10 then 5
            when orders_last_year >= 7 then 4
            when orders_last_year >= 5 then 3
            when orders_last_year >= 3 then 2
            else 1
        end as frequency_score,

        -- Monetary - revenue in last year
        revenue_last_year,
        
        -- Monetary score (5=highest value, 1=lowest value)
        case
            when revenue_last_year >= 50000 then 5
            when revenue_last_year >= 25000 then 4
            when revenue_last_year >= 10000 then 3
            when revenue_last_year >= 5000 then 2
            else 1
        end as monetary_score
        
    from 
        customer_orders
),

-- Generate segment 
final as (
    select 
        -- Join customer attributes 
        cp.customer_id,
        cp.customer_name,
        cp.market_segment,
        cp.nation_name,
        cp.region_name,
        cp.balance_tier,

        -- Join order metrics
        co.total_orders,
        co.total_revenue,
        co.avg_order_value,
        co.first_order_date,
        co.most_recent_order_date,
        co.days_since_last_order,
        
        -- RFM components
        rfm.recency_score,
        rfm.frequency_score,
        rfm.monetary_score,

        -- Combined RFM score (3-15 scale)
        (rfm.recency_score + rfm.frequency_score + rfm.monetary_score) as rfm_score,

        -- RFM segment (e.g '555', '111')
        concat(
            cast(rfm.recency_score as varchar),
            cast(rfm.frequency_score as varchar), 
            cast(rfm.monetary_score as varchar)
        ) as rfm_segment,

        -- Create customer segments based on total spent
        case
            when total_revenue > 1000000 then 'Platinum'
            when total_revenue > 500000 then 'Gold'
            when total_revenue > 100000 then 'Silver'
            else 'Bronze'
        end as spending_segment,

        -- Customer lifecycle stage 
        case 
            when co.total_orders is null then 'New'
            when co.total_orders = 1 and co.days_since_last_order <= 30 then 'New'
            when co.total_orders > 1 and co.days_since_last_order <= 90 then 'Active'
            when co.total_orders >= 4 and co.days_since_last_order <= 180 then 'Loyal'
            when co.days_since_last_order between 91 and 180 then 'At Risk'
            when co.days_since_last_order between 181 and 365 then 'Churning'
            when co.days_since_last_order > 365 then 'Inactive'
            else 'Unknown'
        end as lifecycle_stage,

        -- Order frequency segment
        case
            when co.orders_last_year = 0 then 'Inactive'
            when co.orders_last_year = 1 then 'One-time'
            when co.orders_last_year between 2 and 4 then 'Occasional'
            when co.orders_last_year between 5 and 12 then 'Regular'
            when co.orders_last_year > 12 then 'Frequent'
            else 'Unknown'
        end as purchase_frequency_segment,
        
        -- AOV segment
        case
            when co.avg_order_value < 1000 then 'Low AOV'
            when co.avg_order_value between 1000 and 5000 then 'Medium AOV'
            when co.avg_order_value between 5001 and 10000 then 'High AOV'
            when co.avg_order_value > 10000 then 'Very High AOV'
            else 'Unknown'
        end as aov_segment,

        -- Customer value tier (using combined RFM)
        case
            when (rfm.recency_score + rfm.frequency_score + rfm.monetary_score) >= 13 then 'High Value'
            when (rfm.recency_score + rfm.frequency_score + rfm.monetary_score) >= 9 then 'Medium Value'
            when (rfm.recency_score + rfm.frequency_score + rfm.monetary_score) >= 5 then 'Low Value'
            else 'Very Low Value'
        end as customer_value_tier,

        -- Combined business segment (for targeting)
        case
            when co.total_orders is null or co.total_orders = 0 then 'Prospect'
            when (
                (rfm.recency_score + rfm.frequency_score + rfm.monetary_score) >= 13 
                and co.days_since_last_order <= 90
            ) then 'High Value Active'
            when (
                (rfm.recency_score + rfm.frequency_score + rfm.monetary_score) >= 13 
                and co.days_since_last_order > 90
            ) then 'High Value At Risk'
            when (
                (rfm.recency_score + rfm.frequency_score + rfm.monetary_score) >= 9 
                and co.days_since_last_order <= 90
            ) then 'Medium Value Active'
            when (
                (rfm.recency_score + rfm.frequency_score + rfm.monetary_score) >= 9 
                and co.days_since_last_order > 90
            ) then 'Medium Value At Risk'
            when co.total_orders = 1 and co.days_since_last_order <= 90 then 'New Customer'
            when co.days_since_last_order > 365 then 'Inactive'
            else 'Regular Customer'
        end as business_segment,

        -- Metadata
        current_timestamp as dbt_updated_at

    from customer_profile cp
    
    left join customer_orders co 
        on cp.customer_id = co.customer_id 

    left join rfm_components rfm 
        on cp.customer_id = rfm.customer_id
)

select * from final