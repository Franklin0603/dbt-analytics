-- Test to ensure customer segmentation rules are applied correctly
with validation as (
    select
        customer_key,
        total_spent,
        spending_segment,
        case
            when total_spent > 1000000 then 'PLATINUM'
            when total_spent > 500000 then 'GOLD'
            when total_spent > 100000 then 'SILVER'
            else 'BRONZE'
        end as expected_segment
    from {{ ref('dim_customer_profile') }}
)

select *
from validation
where spending_segment != expected_segment