{{
    config(
        materialized = 'table',
        unique_key = 'date_key',
        tags = ['core', 'dimension', 'date']
    )
}}

with date_spine as (
    -- Generate date spine from 2010 to 10 years in the future
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2010-01-01' as date)",
        end_date="cast(current_date + interval '10 years' as date)"
    ) }}
),

date_dimension as (
    select
        -- Date keys
        cast({{ dbt_utils.generate_surrogate_key(['date_day']) }} as varchar(32)) as date_key,
        cast(date_day as date) as date_day,
        
        -- Date attributes
        extract('year' from date_day) as year,
        extract('month' from date_day) as month,
        extract('day' from date_day) as day_of_month,
        extract('quarter' from date_day) as quarter,
        -- PostgreSQL's extract('dow') returns 0-6 where Sunday=0
        extract('dow' from date_day)::integer + 1 as day_of_week, -- Adjust so Monday=1, Sunday=7
        extract('doy' from date_day) as day_of_year,
        -- PostgreSQL week of year (returns 1-53)
        to_char(date_day, 'WW')::integer as week_of_year,
        
        -- Date naming
        to_char(date_day, 'YYYY-MM-DD') as date_string,
        to_char(date_day, 'YYYYMMDD') as date_id,
        to_char(date_day, 'YYYY-MM') as year_month_id,
        to_char(date_day, 'Mon') as month_short_name,
        to_char(date_day, 'Month') as month_long_name,
        to_char(date_day, 'Dy') as day_short_name,
        to_char(date_day, 'Day') as day_long_name,
        to_char(date_day, 'Dy') as day_name_capitalized,
        'Q' || extract('quarter' from date_day) as quarter_name,
        
        -- Week calculations
        date_trunc('week', date_day)::date as week_start_date,
        (date_trunc('week', date_day) + interval '6 days')::date as week_end_date,
        
        -- Month calculations
        date_trunc('month', date_day)::date as month_start_date,
        (date_trunc('month', date_day) + interval '1 month - 1 day')::date as month_end_date,
        extract('day' from (date_trunc('month', date_day) + interval '1 month - 1 day')) as days_in_month,
        
        -- Quarter calculations
        date_trunc('quarter', date_day)::date as quarter_start_date,
        (date_trunc('quarter', date_day) + interval '3 months - 1 day')::date as quarter_end_date,
        
        -- Year calculations
        date_trunc('year', date_day)::date as year_start_date,
        (date_trunc('year', date_day) + interval '1 year - 1 day')::date as year_end_date,
        
        -- Time period flags
        case when date_day = current_date then true else false end as is_current_day,
        case when date_trunc('month', date_day)::date = date_trunc('month', current_date)::date then true else false end as is_current_month,
        case when date_trunc('quarter', date_day)::date = date_trunc('quarter', current_date)::date then true else false end as is_current_quarter,
        case when date_trunc('year', date_day)::date = date_trunc('year', current_date)::date then true else false end as is_current_year,
        
        -- Previous time period flags
        case when date_trunc('month', date_day)::date = (date_trunc('month', current_date) - interval '1 month')::date then true else false end as is_previous_month,
        case when date_trunc('quarter', date_day)::date = (date_trunc('quarter', current_date) - interval '3 months')::date then true else false end as is_previous_quarter,
        case when date_trunc('year', date_day)::date = (date_trunc('year', current_date) - interval '1 year')::date then true else false end as is_previous_year,
        
        -- Year-to-date flag
        case 
            when extract('year' from date_day) = extract('year' from current_date) 
            and date_day <= current_date 
            then true else false 
        end as is_ytd,
        
        -- Quarter-to-date flag
        case 
            when extract('year' from date_day) = extract('year' from current_date)
            and extract('quarter' from date_day) = extract('quarter' from current_date)
            and date_day <= current_date 
            then true else false 
        end as is_qtd,
        
        -- Month-to-date flag
        case 
            when extract('year' from date_day) = extract('year' from current_date)
            and extract('month' from date_day) = extract('month' from current_date)
            and date_day <= current_date 
            then true else false 
        end as is_mtd,
        
        -- Rolling time periods
        case when (date_day + interval '7 days') > current_date and date_day <= current_date then true else false end as is_last_7_days,
        case when (date_day + interval '30 days') > current_date and date_day <= current_date then true else false end as is_last_30_days,
        case when (date_day + interval '90 days') > current_date and date_day <= current_date then true else false end as is_last_90_days,
        case when (date_day + interval '365 days') > current_date and date_day <= current_date then true else false end as is_last_365_days,
        
        -- Calendar vs Fiscal Year (assuming fiscal year starts April 1)
        extract('year' from date_day) as calendar_year,
        case 
            when extract('month' from date_day) >= 4 
            then extract('year' from date_day) 
            else extract('year' from date_day) - 1 
        end as fiscal_year,
        
        case 
            when extract('month' from date_day) >= 4 
            then extract('month' from date_day) - 3
            else extract('month' from date_day) + 9
        end as fiscal_month,
        
        case 
            when extract('month' from date_day) between 4 and 6 then 1
            when extract('month' from date_day) between 7 and 9 then 2
            when extract('month' from date_day) between 10 and 12 then 3
            else 4
        end as fiscal_quarter,
        
        -- Weekend/Weekday indicator
        case 
            when extract('dow' from date_day) in (0, 6) then 'Weekend' 
            else 'Weekday' 
        end as weekend_flag,
        
        case 
            when extract('dow' from date_day) in (0, 6) then true 
            else false 
        end as is_weekend,
        
        -- Holiday indicators (US example - can be expanded for your needs)
        case
            when (extract('month' from date_day) = 1 and extract('day' from date_day) = 1) then 'New Year''s Day'
            when (extract('month' from date_day) = 7 and extract('day' from date_day) = 4) then 'Independence Day'
            when (extract('month' from date_day) = 12 and extract('day' from date_day) = 25) then 'Christmas Day'
            -- Add more holidays as needed
            else null
        end as holiday_name,
        
        case
            when (extract('month' from date_day) = 1 and extract('day' from date_day) = 1) 
                or (extract('month' from date_day) = 7 and extract('day' from date_day) = 4)
                or (extract('month' from date_day) = 12 and extract('day' from date_day) = 25)
                -- Add more holidays as needed
            then true
            else false
        end as is_holiday,
        
        -- Business day flags (non-holiday weekdays)
        case 
            when extract('dow' from date_day) not in (0, 6) 
                and case
                    when (extract('month' from date_day) = 1 and extract('day' from date_day) = 1) 
                        or (extract('month' from date_day) = 7 and extract('day' from date_day) = 4)
                        or (extract('month' from date_day) = 12 and extract('day' from date_day) = 25)
                    then true
                    else false
                end = false
            then true
            else false
        end as is_business_day,
        
        -- Season (Northern Hemisphere)
        case
            when (extract('month' from date_day) = 12 and extract('day' from date_day) >= 21) 
                or extract('month' from date_day) = 1 
                or extract('month' from date_day) = 2 
                or (extract('month' from date_day) = 3 and extract('day' from date_day) < 20) 
                then 'Winter'
            when (extract('month' from date_day) = 3 and extract('day' from date_day) >= 20) 
                or extract('month' from date_day) = 4 
                or extract('month' from date_day) = 5 
                or (extract('month' from date_day) = 6 and extract('day' from date_day) < 21) 
                then 'Spring'
            when (extract('month' from date_day) = 6 and extract('day' from date_day) >= 21) 
                or extract('month' from date_day) = 7 
                or extract('month' from date_day) = 8 
                or (extract('month' from date_day) = 9 and extract('day' from date_day) < 22) 
                then 'Summer'
            when (extract('month' from date_day) = 9 and extract('day' from date_day) >= 22) 
                or extract('month' from date_day) = 10 
                or extract('month' from date_day) = 11 
                or (extract('month' from date_day) = 12 and extract('day' from date_day) < 21) 
                then 'Fall'
        end as season,
        
        -- ISO Week and Year
        to_char(date_day, 'IYYY') as iso_year,
        to_char(date_day, 'IW') as iso_week_number,
        to_char(date_day, 'IYYY') || '-' || to_char(date_day, 'IW') as iso_year_week,
        
        -- ISO week dates - PostgreSQL ISO week starts on Monday by default
        date_trunc('week', date_day)::date as iso_week_start_date,
        (date_trunc('week', date_day) + interval '6 days')::date as iso_week_end_date,
        
        -- Time since metrics
        extract('day' from age(current_date, date_day))::integer as days_ago,
        (extract('day' from age(current_date, date_day)) / 7)::integer as weeks_ago,
        (extract('year' from age(current_date, date_day)) * 12 + extract('month' from age(current_date, date_day)))::integer as months_ago,
        (extract('year' from age(current_date, date_day)) * 4 + extract('quarter' from age(current_date, date_day)))::integer as quarters_ago,
        extract('year' from age(current_date, date_day))::integer as years_ago,
        
        -- PostgreSQL doesn't have a direct Julian date function, so we'll use a calculation
        -- This is days since January 1, 4713 BC
        extract(epoch from date_day)::bigint / 86400 + 2440588 as julian_date,
        
        -- Metadata
        current_timestamp as dbt_updated_at

    from date_spine
)

select * from date_dimension