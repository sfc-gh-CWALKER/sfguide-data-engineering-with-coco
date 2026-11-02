---
name: dbt-test-triage
description: Triage failing dbt tests after a build and draft fixes for simple failures. Use when dbt build fails or for routine project upkeep.
---

# Conventions

1. Never edit models or tests on `main`. Create `fix/<short-description>` before changing anything.
2. Only draft fixes automatically for SIMPLE failures: an `accepted_values` list missing a legitimate value, a `relationships` test pointing at a renamed column, or a stale source column name. Everything else is REPORT ONLY.
3. Before proposing a new accepted value, query the actual distinct values with row counts and say whether the value looks legitimate or like bad data.
4. Never weaken a test (delete it, add `where:`, change severity) without explicit approval.
5. Write the report to `proposals/dbt-triage-<YYYY-MM-DD>.md` and stop for approval before committing.

# Workflow

1. Run `dbt build --project-dir dbt/` and read `target/run_results.json`.
2. For each failure, capture test, model, column, failing row count, and sample failing values.
3. Classify each failure as SIMPLE (draft fix), DATA ISSUE (report upstream), or NEEDS INVESTIGATION.
4. For SIMPLE failures, show the exact proposed diff and the evidence.
5. Write the triage report, then ask to approve, edit, or reject each fix.
6. After approval, apply the fix on the `fix/` branch, run `dbt build --select <model> --project-dir dbt/`, and commit.
