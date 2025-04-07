-- models/marts/reporting/viz_daily_sales_trends.sql
with daily_metrics as (
    select
        order_day,
        total_orders,
        total_delivered_value as revenue,
        on_time_delivery_rate,
        shipping_efficiency_score,
        -- Time components for filtering
        extract(year from order_day) as year,
        extract(month from order_day) as month,
        extract(dow from order_day) as day_of_week,
        -- Additional metrics
        late_deliveries,
        early_deliveries,
        avg_ship_delay
    from {{ ref('rpt_order_fulfillment') }}
),

-- Add moving averages and growth rates
final as (
    select
        *,
        -- 7-day moving averages
        avg(revenue) over (
            order by order_day
            rows between 6 preceding and current row
        ) as revenue_7day_ma,
        
        -- Month-to-date totals
        sum(revenue) over (
            partition by year, month
            order by order_day
            rows between unbounded preceding and current row
        ) as mtd_revenue,
        
        -- Year-over-year growth
        round(
            ((revenue - lag(revenue, 365) over (order by order_day)) / 
            nullif(lag(revenue, 365) over (order by order_day), 0) * 100),
            2
        ) as yoy_growth
    from daily_metrics
)

select * from final