# ADR-001: dbt Project Naming Conventions

## Status

Accepted

## Context

We need consistent naming conventions across our dbt project to ensure maintainability and readability.

## Decision

We will adopt the following naming conventions:

### Models

- Staging models: `stg_<source>__<entity>.sql`
- Intermediate models: `int_<entity>_<transformation>.sql`
- Fact models: `fct_<entity>_<description>.sql`
- Dimension models: `dim_<entity>.sql`

### Tests

- Generic tests in `tests/generic/`
- Custom tests in `tests/specific/`
- Test files: `test_<model>_<assertion>.sql`

### Macros

- Utility macros: `get_<action>_<entity>.sql`
- Transformation macros: `transform_<action>.sql`
- Testing macros: `test_<assertion>.sql`

### Documentation

- Model docs in `.yml` files alongside models
- General documentation in `docs/` directory
- ADRs in `docs/decisions/`

## Consequences

- Improved code organization and discoverability
- Easier onboarding for new team members
- Consistent codebase across the project
