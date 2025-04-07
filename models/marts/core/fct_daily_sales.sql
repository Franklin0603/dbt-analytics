WITH order_items AS (
    SELECT * FROM {{ ref('int_tpch_order_items') }}
),

daily_sales AS (
    SELECT
        date_trunc('day', order_date) AS sale_date,
        count(distinct order_id) AS total_orders,
        count(*) AS total_line_items,
        sum(quantity) AS total_quantity,
        sum(base_price) AS total_base_price,
        sum(discount_amount) AS total_discounts,
        sum(tax_amount) AS total_tax,
        sum(final_price) AS total_sales,
        sum(gross_margin) AS total_margin,

        -- Averages
        avg(final_price) AS avg_order_value,
        avg(margin_percentage) AS avg_margin_percentage,

        -- Delivery metrics
        avg(ship_delay) AS avg_ship_delay,
        sum(case when delivery_status = 'LATE' then 1 else 0 end) AS late_deliveries,
        sum(case when delivery_status = 'EARLY' then 1 else 0 end) AS early_deliveries,

        -- Additional time-based metrics
        date_part('dow', order_date) AS day_of_week,
        date_part('month', order_date) AS month,
        date_part('quarter', order_date) AS quarter,
        date_part('year', order_date) AS year

    FROM order_items
    GROUP BY 1, order_date 
),

final AS (
    SELECT
        *,
        -- Calculate moving averages
        avg(total_sales) OVER (
            ORDER BY sale_date
            ROWS BETWEEN 7 PRECEDING AND CURRENT ROW
        ) AS sales_7_day_moving_avg,

        avg(total_sales) OVER (
            ORDER BY sale_date
            ROWS BETWEEN 30 PRECEDING AND CURRENT ROW
        ) AS sales_30_day_moving_avg,

        -- Calculate growth rates
        (total_sales - lag(total_sales) OVER (ORDER BY sale_date)) /
        nullif(lag(total_sales) OVER (ORDER BY sale_date), 0) * 100 
        AS daily_sales_growth,

        -- Calculate relative metrics
        total_sales / nullif(avg(total_sales) OVER (), 0) * 100 
        AS sales_percent_of_average

    FROM daily_sales
)

SELECT * FROM final
