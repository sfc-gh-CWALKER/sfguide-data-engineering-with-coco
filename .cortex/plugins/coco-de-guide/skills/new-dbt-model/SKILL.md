---
name: new-dbt-model
description: Create a new dbt model in this project. Use when adding a model for a new source table or analytical use case.
---

# Conventions

1. Always use `dbt build` (not `dbt run`) so tests run together with compilation.
2. Every model's primary key must have `not_null` and `unique` tests in `_schema.yml`.
3. Reference all raw tables through `_sources.yml`. Never reference the source database directly in model SQL.

# Workflow

1. Confirm which source table(s) to model — ask if not specified.
2. Write the model SQL in `dbt/models/<model_name>.sql` using `{{ source('<source>', '<table>') }}` references.
3. Add the model entry to `dbt/models/_schema.yml` with a description and tests for the primary key.
4. Run `dbt build --select <model_name> --project-dir dbt/` and report the result.
