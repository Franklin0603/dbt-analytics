# Troubleshooting Guide

## Common Issues and Solutions

### 1. dbt Command Issues

#### Problem: dbt commands not found

```bash
-bash: dbt: command not found
```

**Solution:**

1. Verify Python environment is activated
2. Reinstall dbt:
   ```bash
   pip install --upgrade dbt-core dbt-postgres
   ```
3. Verify PATH includes dbt

#### Problem: Profile loading error

```
Runtime Error: Could not find profile named 'tpch_analytics'
```

**Solution:**

1. Check profiles.yml location
2. Copy profiles.yml.example to ~/.dbt/profiles.yml
3. Update credentials

### 2. Model Execution Issues

#### Problem: Model fails with relation not found

```sql
ERROR: relation "schema.table" does not exist
```

**Solution:**

1. Check source table existence
2. Verify schema permissions
3. Run upstream models:
   ```bash
   dbt run --models +model_name
   ```

#### Problem: Incremental model issues

```sql
ERROR: Cannot find previous build of incremental model
```

**Solution:**

1. Check if table exists
2. Run with full-refresh:
   ```bash
   dbt run --full-refresh --models model_name
   ```
3. Verify incremental strategy

### 3. Testing Issues

#### Problem: Generic test failures

```
ERROR: unique test failed on column_name
```

**Solution:**

1. Investigate data using:
   ```sql
   SELECT column_name, COUNT(*)
   FROM table_name
   GROUP BY column_name
   HAVING COUNT(*) > 1
   ```
2. Fix data quality issues
3. Update test configurations

#### Problem: Custom test failures

**Solution:**

1. Debug test SQL
2. Check input data
3. Verify business logic

### 4. Performance Issues

#### Problem: Slow model execution

**Solution:**

1. Review model materialization
2. Check join conditions
3. Add appropriate indexes
4. Consider partitioning

#### Problem: Resource constraints

**Solution:**

1. Adjust threads in profiles.yml
2. Optimize model dependencies
3. Use incremental processing

### 5. Git and Version Control

#### Problem: Pre-commit hook failures

**Solution:**

1. Run SQLFluff locally:
   ```bash
   sqlfluff fix models/
   ```
2. Update SQL formatting
3. Verify yaml formatting

#### Problem: Merge conflicts

**Solution:**

1. Fetch latest changes
2. Rebase branch
3. Resolve conflicts manually

### 6. Documentation Issues

#### Problem: dbt docs generate fails

**Solution:**

1. Check yaml syntax
2. Verify model references
3. Update manifest.json

### 7. Environment Setup

#### Problem: Package installation fails

**Solution:**

1. Clear package cache:
   ```bash
   dbt clean
   ```
2. Update packages.yml
3. Reinstall dependencies:
   ```bash
   dbt deps
   ```

#### Problem: Database connection issues

**Solution:**

1. Verify credentials
2. Check network access
3. Test connection:
   ```bash
   dbt debug
   ```

## Debugging Tips

### 1. Model Debugging

```sql
-- Add debug statements
{{ print("Debugging model: " ~ model.name) }}

-- Check intermediate results
WITH debug_cte AS (
    SELECT COUNT(*) as row_count
    FROM {{ ref('upstream_model') }}
)
SELECT * FROM debug_cte
```

### 2. Macro Debugging

```sql
-- Test macro with sample values
{% set test_value = 'sample' %}
{{ print(my_macro(test_value)) }}
```

### 3. Performance Analysis

```sql
-- Check execution plan
EXPLAIN ANALYZE
SELECT * FROM {{ ref('model_name') }}
```

## Getting Additional Help

1. **Documentation Resources**

   - Project documentation
   - dbt documentation
   - SQL reference guides

2. **Support Channels**

   - Team chat
   - Issue tracker
   - Weekly meetings

3. **Escalation Process**
   - Document issue
   - Gather logs
   - Create detailed report
