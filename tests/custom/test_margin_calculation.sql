-- Test to ensure margins are calculated correctly
select
    order_key,
    line_number,
    final_price,
    gross_margin,
    margin_percentage
from {{ ref('fct_daily_sales') }}
where gross_margin > final_price
   or margin_percentage > 100
   or margin_percentage < -100