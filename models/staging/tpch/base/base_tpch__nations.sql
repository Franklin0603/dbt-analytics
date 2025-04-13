{{
 config(
  materialized='view',
  schema='staging',
  tags = ['tpch', 'base']
 )
}}

with source as (
  select * from {{ source('tpch', 'nation') }}
),

renamed as (
  select
    -- ids
    n_nationkey as nation_id,
    n_regionkey as region_id,

    -- text fields
    n_name as nation_name,
    n_comment as comment,

    -- metadata
    current_timestamp as created_at,
    current_timestamp as updated_at

  from source
),

final as (
  select
    nation_id,
    nation_name,
    region_id,
    comment,
    created_at,
    updated_at
  from renamed
)

select * from final

{% if is_incremental() %}
where created_at > (select max(created_at) from {{ this }})
{% endif %}