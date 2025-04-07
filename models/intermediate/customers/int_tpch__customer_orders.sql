{{
    config(
        materialized = 'table',
        tags = ['tpch', 'intermediate', 'customer']
    )
}}

with orders as (
    select * from {{ ref("stg_tpch_orders") }}
),

line_items as (
    select * from {{ ref("stg_tpch_lineitem") }}
),

-- Aggregate line items to order level
order_summaries as (
    select
        order_id,
        count(*) as number_of_items,
        sum(quantity) as total_quantity,
        sum(extended_price) as total_extended_price,
        sum(discounted_price) as total_discounted_price,
        sum(final_price) as total_final_price,
        min(ship_date) as earliest_ship_date,
        max(ship_date) as latest_ship_date,
        count(case when is_shipped_on_time then 1 end)::decimal / nullif(count(*), 0) as on_time_shipping_rate
    from line_items
    group by 1
),

-- Calculate time-based metrics for different periods
customer_order_metrics as (
    select 
        orders.customer_id,

        -- Order count metrics 
        count(distinct orders.order_id) as total_orders,
        count(distinct case when orders.order_date >= current_date - interval '1 year' then orders.order_id end) as orders_last_year,
        count(distinct case when orders.order_date >= current_date - interval '3 months' then orders.order_id end) as orders_last_3_months,
        count(distinct case when orders.order_date >= current_date - interval '1 month' then orders.order_id end) as orders_last_month,

        -- Order date metrics
        min(orders.order_date) as first_order_date,
        max(orders.order_date) as most_recent_order_date,
        extract(day from age(max(orders.order_date), min(orders.order_date))) as customer_tenure_days,
        extract(day from age(current_date, max(orders.order_date))) as days_since_last_order,

        -- Order frequency metrics
        case 
            when count(distinct orders.order_id) <= 1 then null 
            else extract(day from age(max(orders.order_date), min(orders.order_date))) / nullif(count(distinct orders.order_id) - 1, 0)
        end as avg_days_between_orders,

        -- Financial metrics
        sum(orders.total_price) as total_revenue,
        sum(case when orders.order_date >= current_date - interval '1 year' then orders.total_price else 0 end) as revenue_last_year,
        sum(case when orders.order_date >= current_date - interval '3 months' then orders.total_price else 0 end) as revenue_last_3_months,
        sum(case when orders.order_date >= current_date - interval '1 month' then orders.total_price else 0 end) as revenue_last_month,

        -- Average order value
        avg(orders.total_price) as avg_order_value,
        avg(case when orders.order_date >= current_date - interval '1 year' then orders.total_price end) as avg_order_value_last_year,

        -- Item & quantity metrics (joined from line items)
        avg(os.number_of_items) as avg_items_per_order,
        avg(os.total_quantity) as avg_quantity_per_order,
        sum(os.number_of_items) as total_items_ordered,
        sum(os.total_quantity) as total_quantity_ordered,

        -- Shipping performance metrics
        avg(os.on_time_shipping_rate) as avg_on_time_shipping_rate,

        -- Status distribution
        count(distinct case when orders.order_status = 'Fulfilled' then orders.order_id end)::decimal / nullif(count(distinct orders.order_id), 0) as fulfilled_order_ratio,

        -- Shipping time metrics
        avg(os.latest_ship_date - orders.order_date) as avg_days_to_ship,


        -- Metadata
        current_timestamp as dbt_updated_at

    from orders
    left join order_summaries os 
        on orders.order_id = os.order_id
    group by orders.customer_id
)

select * from customer_order_metrics