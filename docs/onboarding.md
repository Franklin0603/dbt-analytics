# TPC-H Analytics Project Onboarding Guide

## Overview

This dbt project transforms TPC-H data into analytics-ready models following dimensional modeling best practices.

## Prerequisites

- Python 3.9+
- dbt 1.5+
- Access to the data warehouse
- Git

## Getting Started

1. Clone the repository:

```bash
git clone [repository-url]
cd tpch-analytics
```

2. Set up your Python environment:

```bash
pip install -r requirements.txt
```

3. Configure your dbt profile:

```bash
cp profiles.yml.example profiles.yml
# Edit profiles.yml with your credentials
```

4. Install dbt packages:

```bash
dbt deps
```

5. Run the project:

```bash
dbt build
```

## Project Structure

- `models/`: Contains all dbt models
  - `staging/`: Initial data models
  - `intermediate/`: Transformed models
  - `marts/`: Final presentation layer
- `tests/`: Data quality tests
- `macros/`: Reusable SQL functions
- `docs/`: Project documentation

## Development Workflow

1. Create a new branch for your changes
2. Make your changes following our [naming conventions](decisions/adr-001-naming-conventions.md)
3. Test your changes: `dbt test`
4. Create a pull request

## Additional Resources

- [dbt Documentation](https://docs.getdbt.com)
- [Project Wiki](link-to-wiki)
- [Team Contact Information](link-to-contacts)
