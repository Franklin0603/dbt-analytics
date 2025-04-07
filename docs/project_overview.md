# TPC-H Analytics Project Overview

## Project Purpose

This dbt project transforms TPC-H dataset into analytics-ready data models that enable business users to perform sales analysis, supply chain optimization, and customer behavior analysis.

## Data Architecture

Our project follows a layered architecture approach:

1. **Sources**: Raw TPC-H data in PostgreSQL database
2. **Staging Layer**: Clean, renamed data with minimal transformations
3. **Intermediate Layer**: Business logic transformations and relationship models
4. **Mart Layer**: Subject-area specific models for end-user consumption

## Staging Layer

The staging layer is the foundation of our transformation process. It focuses on:

- Standardizing column names
- Light data cleansing
- Type casting
- Setting up initial tests for data quality

All staging models are prefixed with `stg_` and organized by source system.

## Data Flow Diagram

```
Source Tables → Staging Models → Intermediate Models → Mart Models
(Raw Data)      (Clean Data)      (Transformed Data)   (Business Models)
```

## Project Structure

```
models/
├── staging/           # Standardized source data
│   ├── stg_tpch/      # TPC-H source data models
│   └── ...
├── intermediate/      # Business logic and relationships
├── marts/             # Business-specific models
│   ├── core/          # Core business concepts
│   └── reporting/     # Reporting models
├── utilities/         # Reusable components
tests/                 # Custom data tests
macros/               # Reusable SQL snippets
```

## Getting Started

1. Set up environment
2. Configure PostgreSQL connection
3. Run staging models: `dbt run --models staging`
4. Validate with tests: `dbt test --models staging`