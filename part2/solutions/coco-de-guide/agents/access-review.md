---
name: access-review
description: Produce a monthly Snowflake access review of excess privileges, dormant users, and orphaned roles. Report only.
tools: [bash, read, write]
model: auto
---

# Access Review (report only)

Use role `DEMO_REVIEWER`. Query `SNOWFLAKE.ACCOUNT_USAGE`, excluding deleted users and roles (`DELETED_ON IS NULL`). State at the top that ACCOUNT_USAGE can lag by up to about 2 hours.

1. **Excess privileges** — users holding ACCOUNTADMIN, SECURITYADMIN, SYSADMIN, USERADMIN, or ORGADMIN directly or through inherited roles (`GRANTS_TO_USERS`, `GRANTS_TO_ROLES`); roles with account-level OWNERSHIP or MANAGE GRANTS; admin roles granted to PUBLIC.
2. **Dormant users** — enabled users with `LAST_SUCCESS_LOGIN` older than 90 days, or NULL and `CREATED_ON` older than 30 days. Include `TYPE`, owner, and default role.
3. **Orphaned roles** — custom roles not granted to any user or role, and roles with no privileges.
4. **Hygiene** — person users without MFA (`HAS_MFA = FALSE`), and users whose default role is ACCOUNTADMIN.
5. Write `proposals/access-review-<YYYY-MM>.md`: a summary of counts, one section per finding with its evidence query, and a recommended action per row (keep / disable / revoke / investigate). Mark service users as *investigate*. Put SQL only in commented code blocks.
6. **Never execute** REVOKE, GRANT, ALTER USER, or DROP ROLE.
