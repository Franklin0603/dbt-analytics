# ADR-002: Data Modeling Strategy and Pattern Selection

## Status

Accepted

## Context

We need to establish consistent modeling patterns for our TPC-H analytics project to ensure scalability, maintainability, and performance. The project involves transforming TPC-H source data into analytics-ready models.

## Decision

We will implement a multi-layered transformation approach following the dbt best practices:

### Layer 1: Source

- Source tables will be referenced using `source()` macros
- Each source will have its own schema
- Source freshness tests will be implemented

### Layer 2: Staging

- One-to-one relationship with source tables
- Light transformations only:
  - Column renaming
  - Type casting
  - Basic data cleaning
  - NULL handling
- No joins at this layer
- Prefix: `stg_`

### Layer 3: Intermediate

- Business logic implementation
- Complex transformations
- Joining related staging models
- Prefix: `int_`

### Layer 4: Marts

- Dimensional modeling approach
  - Facts: Transaction/event-based models (prefix: `fct_`)
  - Dimensions: Description/attribute-based models (prefix: `dim_`)
- Star schema design for better query performance
- Conformed dimensions across marts

### Design Patterns

1. **Slowly Changing Dimensions (SCD)**

   - Type 1: Overwrite
   - Type 2: Track history with effective dates
   - Implementation using dbt snapshots

2. **Incremental Loading**

   - Use `incremental` materialization for large fact tables
   - Implement appropriate incremental strategies per model

3. **Materialization Strategy**
   - Views: For simple transformations
   - Tables: For complex transformations
   - Incremental: For large fact tables
   - Ephemeral: For simple intermediate calculations

## Consequences

- Clear separation of concerns between layers
- Improved maintainability and debugging
- Optimized warehouse performance
- Consistent dimensional modeling across the project
- Easier onboarding for new team members
