# coco-de-guide

Tricon's dbt standards and operations automations.

- **Skills:** `new-dbt-model`, `dbt-test-triage`
- **Subagents:** `dbt-review`, `classification-sweep`, `access-review`, `kpi-report`, `anomaly-explainer`, `warehouse-advisor`
- **Hook:** blocks `dbt ... --target prod` (use CI/CD for production)

Every automation writes proposals to `proposals/` and waits for human approval before changing grants, masking, or warehouses.
