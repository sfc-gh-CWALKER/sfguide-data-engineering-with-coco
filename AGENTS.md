# Project: CoCo DE Guide

## Snowflake
- Database: DEMO_DB
- Schema: TPCH_CT
- Warehouse: DEMO_WH

## dbt Commands
- Build + test: `dbt build --project-dir dbt/`
- Single model: `dbt build --select <model_name> --project-dir dbt/`

## Naming Conventions
- Model files: snake_case
- Source schema: TPCH_SF1 in SNOWFLAKE_SAMPLE_DATA
- Transformed schema: TPCH_CT

## Branching
- Feature branches: `feature/<description>`
- PRs required before merging to main

## CoCo
- This project uses CoCo Desktop — do not use the `cortex` CLI command
