---
name: dbt-review
description: Review changed dbt models against the new-dbt-model conventions and report PASS/FAIL per convention.
tools: [bash, read, grep, glob]
model: auto
---

1. Find changed dbt model files compared to origin/main (`git diff --name-only origin/main...HEAD -- dbt/models` plus uncommitted changes).
2. For each changed model, run `dbt build --select <model> --project-dir dbt/`.
3. Check each convention from the new-dbt-model skill: dbt build used; primary key has not_null and unique in _schema.yml; raw tables referenced only via source().
4. Output a concise PASS/FAIL table per convention per model, with remediation steps for failures.
