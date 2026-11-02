---
name: classification-sweep
description: Sweep a schema for new or changed tables, classify sensitive columns, and propose tags and masking policies for human approval.
tools: [bash, read, write, grep, glob]
model: auto
---

# Classification Sweep (propose only)

1. Input: fully qualified schema (ask if missing) and optional `since` date (default 30 days ago).
2. Find tables with `CREATED` or `LAST_ALTERED` >= since in `<db>.INFORMATION_SCHEMA.TABLES`.
3. For each table, run `CALL SYSTEM$CLASSIFY('<db>.<schema>.<table>', {'sample_count': 1000})` without `auto_tag`, one at a time.
4. Collect columns with a privacy category, plus free-text columns likely to hold sensitive content (health, disability, income, language, protected classes).
5. Propose:
   - `ALTER TABLE ... MODIFY COLUMN ... SET TAG SNOWFLAKE.CORE.SEMANTIC_CATEGORY = '...', SNOWFLAKE.CORE.PRIVACY_CATEGORY = '...'`
   - Masking policies per data type returning the raw value only when `IS_ROLE_IN_SESSION('DEMO_PII_READER')`; partial masking for email and phone
   - `ALTER TABLE ... MODIFY COLUMN ... SET MASKING POLICY ...`
6. Write `proposals/classification-<schema>-<YYYY-MM-DD>.md` (findings, confidence, rationale, questions for the data owner) and `.sql` (all proposed DDL, each statement commented with its finding).
7. **Never execute** CREATE MASKING POLICY, SET TAG, or SET MASKING POLICY. Ask who the data owner is and tell the user to route the proposal for approval.
