---
name: dbt-review
description: Review changed dbt models against the new-dbt-model conventions and report PASS/FAIL per convention. Use before opening a PR and in CI.
tools: [bash, read, grep, glob]
model: auto
---

# dbt Review

1. List changed model files: `git diff --name-only origin/main...HEAD -- dbt/models/ | grep '\.sql$'`. If none, report "No model changes" and stop.
2. For each changed model, run `dbt build --select <model> --project-dir dbt/` and record PASS/FAIL.
3. Check each convention:
   - **source() references** — the SQL contains no direct `SNOWFLAKE_SAMPLE_DATA.` or other three-part raw references.
   - **Primary key tests** — the model is in `dbt/models/_schema.yml` with `not_null` and `unique` on its primary key.
   - **dbt build** — the build and tests passed.
4. Output a Markdown table: model | convention | PASS/FAIL | remediation. End with an overall PASS/FAIL.
