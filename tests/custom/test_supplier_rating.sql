-- Test to ensure supplier ratings are calculated correctly
select
    supplier_key,
    supplier_rating,
    profit_margin_percentage,
    on_time_delivery_percentage
from {{ ref('fct_supplier_performance') }}
where supplier_rating > 100
   or supplier_rating < 0
   or supplier_rating != round(
        (
            profit_margin_percentage * 0.3 +
            on_time_delivery_percentage * 0.4 +
            (100 - avg_cost_to_retail_ratio * 100) * 0.3
        ),
        2
    )