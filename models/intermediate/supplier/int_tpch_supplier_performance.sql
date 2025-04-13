with supplier_orders as (
    select
        s.supplier_id,
        s.supplier_name,
        s.nation_id,
        l.order_id,
        l.part_id,
        l.quantity,
        l.extended_price,
        l.discount,
        l.ship_date,
        l.commit_date,
        l.receipt_date,
        p.retail_price,
        ps.supply_cost
    from {{ ref('stg_tpch__suppliers') }} s
    inner join {{ ref('stg_tpch__line_items') }} l
        on s.supplier_id = l.supplier_id
    inner join {{ ref('stg_tpch__parts') }} p
        on l.part_id = p.part_id
    inner join {{ ref('stg_tpch__part_suppliers') }} ps
        on l.part_id = ps.part_id
        and l.supplier_id = ps.supplier_id
),

supplier_metrics as (
    select
        supplier_id,
        supplier_name,
        nation_id,
        
        -- Order metrics
        count(distinct order_id) as total_orders,
        sum(quantity) as total_quantity_supplied,
        sum(extended_price) as total_revenue,
        sum(extended_price * (1 - discount)) as total_discounted_revenue,
        
        -- Cost and margin metrics
        sum(quantity * supply_cost) as total_supply_cost,
        sum(extended_price * (1 - discount) - (quantity * supply_cost)) as total_profit,
        round(
            sum(extended_price * (1 - discount) - (quantity * supply_cost)) / 
            sum(extended_price * (1 - discount)) * 100,
            2
        ) as profit_margin_percentage,
        
        -- Delivery performance
        avg(case when ship_date <= commit_date then 1 else 0 end) * 100 
            as on_time_delivery_percentage,
        avg((commit_date - ship_date)) as avg_delivery_delay,
        
        -- Price competitiveness
        avg(supply_cost / nullif(retail_price, 0)) as avg_cost_to_retail_ratio
        
    from supplier_orders
    group by 1, 2, 3
),

final as (
    select
        sm.*,
        n.nation_name,
        r.region_name,
        
        -- Supplier rating (0-100)
        round(
            (
                (profit_margin_percentage * 0.3) + -- Profitability (30%)
                (on_time_delivery_percentage * 0.4) + -- Reliability (40%)
                ((100 - avg_cost_to_retail_ratio * 100) * 0.3) -- Cost efficiency (30%)
            ),
            2
        ) as supplier_rating,
        
        -- Comparative metrics within nation
        round(
            total_revenue / avg(total_revenue) over (partition by sm.nation_id) * 100,
            2
        ) as revenue_percentage_of_nation,
        
        -- Supplier ranking within nation
        row_number() over (
            partition by n.nation_id 
            order by total_revenue desc
        ) as revenue_rank_in_nation
        
    from supplier_metrics sm
    inner join {{ ref('stg_tpch__nations') }} n
        on sm.nation_id = n.nation_id
    inner join {{ ref('stg_tpch__regions') }} r
        on n.region_id = r.region_id
)

select * from final
