-- models/marts/reporting/rpt_order_fulfillment.sql
with order_items as (
    select * from {{ ref('int_tpch_order_items') }}
),

daily_fulfillment as (
    select
        date_trunc('day', order_date) as order_day,
        count(distinct order_id) as total_orders,
        -- Delivery status counts
        sum(case when delivery_status = 'ON TIME' then 1 else 0 end) as on_time_deliveries,
        sum(case when delivery_status = 'LATE' then 1 else 0 end) as late_deliveries,
        sum(case when delivery_status = 'EARLY' then 1 else 0 end) as early_deliveries,
        
        -- Delays and transit
        avg(ship_delay) as avg_ship_delay,
        avg(transit_time) as avg_transit_time,
        
        -- Calculate fulfillment rates
        round(
            CAST(sum(case when delivery_status = 'ON TIME' then 1 else 0 end) AS NUMERIC) / 
            nullif(count(*), 0) * 100,
            2
        ) as on_time_delivery_rate,

        -- Delivery stats by shipping mode
        avg(ship_delay) filter (where ship_mode = 'AIR') as air_shipping_avg_delay,
        avg(ship_delay) filter (where ship_mode = 'TRUCK') as truck_shipping_avg_delay,
        avg(ship_delay) filter (where ship_mode = 'SHIP') as ship_shipping_avg_delay,
        avg(ship_delay) filter (where ship_mode = 'RAIL') as rail_shipping_avg_delay,
        
        -- Value metrics
        sum(final_price) as total_delivered_value,
        avg(final_price) as avg_order_value,
        count(*) as total_line_items
        
    from order_items
    group by 1
),

final as (
    select
        order_day,
        total_orders,
        total_line_items,
        on_time_deliveries,
        late_deliveries,
        early_deliveries,
        avg_ship_delay,
        avg_transit_time,
        on_time_delivery_rate,
        
        -- Shipping mode metrics
        air_shipping_avg_delay,
        truck_shipping_avg_delay,
        ship_shipping_avg_delay,
        rail_shipping_avg_delay,
        
        -- Value metrics
        total_delivered_value,
        avg_order_value,
        
        -- Calculate moving averages
        avg(on_time_delivery_rate) over (
            order by order_day
            rows between 7 preceding and current row
        ) as otd_7day_moving_avg,
        
        -- Calculate relative performance
        on_time_delivery_rate - avg(on_time_delivery_rate) over () 
            as otd_rate_vs_average,
            
        -- Flag poor performance days
        case
            when on_time_delivery_rate < 80 then 'ALERT'
            when on_time_delivery_rate < 90 then 'WARNING'
            else 'GOOD'
        end as performance_status,
        
        -- Shipping mode distribution
        round(
            CAST(air_shipping_avg_delay AS NUMERIC) / nullif(avg_ship_delay, 0) * 100,
            2
        ) as air_delay_vs_average,

        round(
            CAST(truck_shipping_avg_delay AS NUMERIC) / nullif(avg_ship_delay, 0) * 100,
            2
        ) as truck_delay_vs_average,

        round(
            (
                (100 - coalesce(avg_ship_delay, 0)) * 0.4 +  -- Timeliness (40%)
                on_time_delivery_rate * 0.4 +                 -- Reliability (40%)
                (CAST(total_line_items AS NUMERIC) / total_orders) * 20 -- Efficiency (20%)
            ),
            2
        ) as shipping_efficiency_score
        
    from daily_fulfillment
)

select * from final