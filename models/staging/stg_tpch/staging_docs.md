# Staging Layer Documentation

## Overview

The staging layer is the first transformation layer in our dbt project. It serves to:

1. Rename columns from source systems to our standard naming convention
2. Apply light data cleansing and type casting
3. Prepare data for further transformation in intermediate models

## Testing Approach

Our staging models implement several testing strategies:

### Standard Tests
- **Uniqueness**: Ensuring primary keys are unique
- **Not Null**: Validating required fields
- **Relationships**: Verifying foreign key integrity

### Custom Tests
- **Positive Value Assertion**: Ensures numeric values are positive
- **Date Range Validation**: Confirms dates are within expected ranges
- **Phone Format Validation**: Checks phone numbers conform to expected pattern

### Source Freshness
We test data freshness to ensure our pipeline is functioning correctly and data is being loaded in a timely manner.

## Naming Conventions

- All staging models are prefixed with `stg_`
- Primary keys end with `_id`
- Foreign keys are named after the referenced table with `_id` suffix
- All dates end with `_date`
- All timestamps include `_at` suffix

## Running Tests

To run all staging tests:
```bash
dbt test --models staging
```

To run tests for a specific model:
```bash
dbt test --models stg_tpch_customer
```