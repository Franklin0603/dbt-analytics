-- models/marts/reporting/viz_shipping_performance.sql
with shipping_metrics as (
    select
        order_day,
        -- Shipping efficiency metrics
        air_shipping_avg_delay,
        truck_shipping_avg_delay,
        ship_shipping_avg_delay,
        rail_shipping_avg_delay,
        -- Create separate rows for each shipping mode for easier visualization
        unnest(
            array['AIR', 'TRUCK', 'SHIP', 'RAIL']
        ) as shipping_mode,
        unnest(
            array[
                air_shipping_avg_delay,
                truck_shipping_avg_delay,
                ship_shipping_avg_delay,
                rail_shipping_avg_delay
            ]
        ) as avg_delay
    from {{ ref('rpt_order_fulfillment') }}
),

final as (
    select
        order_day,
        shipping_mode,
        avg_delay,
        -- Calculate relative performance
        round(
            avg_delay / nullif(
                avg(avg_delay) over (
                    partition by shipping_mode
                ),
                0
            ) * 100,
            2
        ) as relative_performance,
        -- Add ranking
        row_number() over (
            partition by date_trunc('month', order_day)
            order by avg_delay
        ) as performance_rank
    from shipping_metrics
    where avg_delay is not null
)

select * from final