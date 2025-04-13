# ADR-004: Incremental Loading Approach

## Status

Accepted

## Context

The TPC-H dataset includes large fact tables that require efficient loading strategies. We need to implement incremental loading to optimize performance and resource utilization.

## Decision

We will implement different incremental strategies based on the nature of the data and use case:

### 1. Timestamp-based Incremental Loading

For tables with reliable updated_at timestamps:

```sql
{{ config(
    materialized='incremental',
    unique_key='id',
    incremental_strategy='timestamp',
    on_schema_change='sync_all_columns'
) }}

SELECT *
FROM {{ source('source_name', 'table_name') }}
{% if is_incremental() %}
WHERE updated_at > (SELECT max(updated_at) FROM {{ this }})
{% endif %}
```

### 2. Unique Key Merge Strategy

For tables requiring full row updates:

```sql
{{ config(
    materialized='incremental',
    unique_key='id',
    incremental_strategy='merge',
    on_schema_change='sync_all_columns'
) }}
```

### 3. Delete+Insert Strategy

For tables requiring periodic full refreshes of specific partitions:

```sql
{{ config(
    materialized='incremental',
    unique_key=['id', 'batch_date'],
    on_schema_change='sync_all_columns'
) }}
```

### Implementation Guidelines

1. **Model Configuration**

   - Always specify `unique_key`
   - Define appropriate `incremental_strategy`
   - Handle schema changes with `on_schema_change`

2. **Performance Optimization**

   - Use partitioning where applicable
   - Implement appropriate indexes
   - Consider batch size for large updates

3. **Error Handling**
   - Implement error logging
   - Define retry strategies
   - Monitor performance metrics

### Specific Use Cases

1. **Fact Tables**

   - Use timestamp-based incremental loading
   - Implement partition pruning
   - Consider daily batch updates

2. **Dimension Tables**

   - Use merge strategy for SCD Type 2
   - Implement full refresh for small dimensions
   - Track effective dates for historical changes

3. **Snapshot Tables**
   - Use dbt snapshots for SCD Type 2
   - Define check columns for change detection
   - Set appropriate update schedule

## Consequences

- Improved processing performance
- Reduced resource utilization
- More complex maintenance requirements
- Need for monitoring and optimization
- Potential for data consistency issues if not properly managed
