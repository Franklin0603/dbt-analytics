# Contributing Guide

## Development Process

### 1. Setting Up Development Environment

```bash
# Clone the repository
git clone [repository-url]
cd tpch-analytics

# Install dependencies
pip install -r requirements.txt

# Install pre-commit hooks
pre-commit install
```

### 2. Branch Naming Convention

- Feature: `feature/description-of-feature`
- Bug Fix: `fix/description-of-bug`
- Documentation: `docs/description-of-changes`
- Refactor: `refactor/description-of-changes`

### 3. Development Workflow

1. Create a new branch from `main`
2. Make your changes following our coding standards
3. Run tests locally
4. Create a pull request
5. Address review comments
6. Merge after approval

## Coding Standards

### SQL Style Guide

1. **Naming**

   - Use lowercase for SQL keywords
   - Use snake_case for object names
   - Follow project naming conventions (see ADR-001)

2. **Formatting**

   - Indent using 4 spaces
   - Maximum line length: 100 characters
   - Place each column on a new line
   - Align joins and where clauses

3. **Example**

```sql
with source_data as (
    select
        customer_id,
        order_date,
        sum(order_amount) as total_amount
    from {{ ref('stg_orders') }}
    where order_status = 'completed'
    group by 1, 2
)
```

### dbt Best Practices

1. **Model Organization**

   - Follow the defined layer structure
   - Use appropriate materialization
   - Document all models

2. **Testing**

   - Add generic tests to all models
   - Write custom tests for complex logic
   - Maintain test coverage

3. **Documentation**
   - Update model documentation
   - Add descriptions to all columns
   - Document assumptions and decisions

## Pull Request Process

### 1. PR Template

- Description of changes
- Related issue/ticket
- Type of change
- Testing approach
- Checklist

### 2. Review Process

- Code review by at least one team member
- All tests must pass
- Documentation must be updated
- SQL style guide followed

### 3. Merge Requirements

- Approved by reviewer
- CI/CD pipeline passed
- No merge conflicts
- Documentation complete

## Testing Guidelines

### 1. Types of Tests

- Generic dbt tests
- Custom SQL tests
- Data quality tests
- Performance tests

### 2. Test Coverage

- All primary keys tested for uniqueness
- All foreign keys tested for referential integrity
- Custom business logic validated
- Edge cases covered

### 3. Running Tests

```bash
# Run all tests
dbt test

# Run specific tests
dbt test --models model_name

# Run specific test types
dbt test --select test_type:generic
```

## Documentation Requirements

### 1. Model Documentation

- Purpose and description
- Business context
- Technical details
- Dependencies

### 2. Column Documentation

- Business definition
- Technical specifications
- Validation rules
- Example values

### 3. Markdown Format

```yaml
version: 2

models:
  - name: model_name
    description: "Detailed description"
    columns:
      - name: column_name
        description: "Column description"
        tests:
          - unique
          - not_null
```

## Support

### Getting Help

- Check existing documentation
- Review similar PRs
- Ask in team channel
- Create an issue

### Useful Resources

- [dbt Documentation](https://docs.getdbt.com)
- [Project Wiki](link-to-wiki)
- [SQL Style Guide](link-to-style-guide)
- [Team Contact List](link-to-contacts)
