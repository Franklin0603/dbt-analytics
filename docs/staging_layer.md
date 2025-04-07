# Staging Layer Documentation

## Purpose

The staging layer serves as the foundational layer of our dbt project. Its primary purposes are:

1. **Data Standardization**: Establish consistent naming conventions across all data sources
2. **Light Transformation**: Perform minimal transformations necessary for data quality
3. **Data Type Casting**: Ensure proper data types for downstream use
4. **Data Quality Testing**: Verify source data meets expectations

## Principles

The staging layer follows these principles:

- **Minimal Transformation**: Only perform essential transformations like renaming and type conversion
- **One-to-One Table Mapping**: Each staging model typically corresponds to one source table
- **Column Naming Consistency**: Follow project naming conventions for all columns
- **Source Data Validation**: Add tests to validate source data quality
- **Complete Data**: All source columns should be included to prevent data loss

## Naming Conventions

- **Models**: All staging models are prefixed with `stg_`
- **Primary Keys**: End with `_id` (e.g., `customer_id`)
- **Foreign Keys**: Named after the referenced entity with `_id` suffix (e.g., `nation_id`)
- **Dates**: End with `_date` (e.g., `order_date`)
- **Timestamps**: End with `_at` (e.g., `loaded_at`)
- **Booleans**: Phrased as yes/no questions (e.g., `is_active`, `has_returns`)

## TPC-H Staging Models

| Model Name | Source Table | Description | Primary Key |
|------------|--------------|-------------|------------|
| `stg_tpch_customer` | customer | Customer information | customer_id |
| `stg_tpch_lineitem` | lineitem | Order line items | lineitem_id |
| `stg_tpch_nation` | nation | Nation reference data | nation_id |
| `stg_tpch_orders` | orders | Order header information | order_id |
| `stg_tpch_part` | part | Product information | part_id |
| `stg_tpch_partsupp` | partsupp | Part-supplier relationships | partsupp_id |
| `stg_tpch_region` | region | Region reference data | region_id |
| `stg_tpch_supplier` | supplier | Supplier information | supplier_id |

## Common Pattern

All staging models follow this common pattern:

```sql
-- 1. Pull from source
with source as (
    select * from {{ source('source_name', 'table_name') }}
),

-- 2. Rename columns
renamed as (
    select
        source_pk as entity_id,
        source_name as entity_name,
        -- other renamed columns
    from source
),

-- 3. Final output
final as (
    select
        *,
        current_timestamp as loaded_at
    from renamed
)

select * from final
```

## Testing Strategy

Each staging model includes these tests:

- **Uniqueness**: Ensuring primary keys are unique
- **Not Null**: Validating required fields
- **Relationships**: Verifying foreign key integrity
- **Custom Tests**: Specific business rules and data quality checks