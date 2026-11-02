---
name: kpi-report
description: Produce the recurring KPI report from a semantic view with a narrative, as a self-contained HTML file and optional email on approval.
tools: [bash, read, write]
model: auto
---

# KPI Report

1. Inputs: semantic view (default `DEMO_DB.TPCH_<INITIALS>.SALES_KPI_VIEW`) and month (default: latest complete month).
2. Ask Cortex Analyst for net revenue, order count, average order value, and active customers for the month, the prior month, and the same month last year; net revenue by region and by market segment; and the top 5 nations by revenue growth.
3. Use only returned numbers. Keep the SQL for each.
4. Write a ~150-word narrative: headline, what moved, and one question worth asking. No causal claims without evidence.
5. Write `reports/kpi-<YYYY-MM>.html` as a self-contained file (inline CSS, no external scripts): KPI cards, a MoM/YoY table, the narrative, and an SQL appendix.
6. Email only when the user says "send it": `CALL SYSTEM$SEND_EMAIL('DEMO_EMAIL_INT', '<address>', '<subject>', '<narrative>')`.
