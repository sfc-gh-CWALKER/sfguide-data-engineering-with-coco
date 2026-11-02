-- =====================================================================
-- Data Engineering with CoCo: admin readiness check (READ-ONLY)
--
-- Run as ACCOUNTADMIN, before and after scripts/admin_setup.sql.
-- Nothing here changes the account. Each query says what "ready" looks like.
--
-- 1. Put every attendee's Snowflake username in the list in check 9.
-- 2. Set the warehouse below to any warehouse you can use (DEMO_WH may not
--    exist yet the first time you run this).
-- 3. Run all, and read each result against the "READY IF" comment above it.
-- =====================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;

-- 1. Shared workshop objects exist ------------------------------------
-- READY IF: one row each for DEMO_ROLE, DEMO_WH and DEMO_DB.
SHOW ROLES LIKE 'DEMO_ROLE';
SHOW WAREHOUSES LIKE 'DEMO_WH';
SHOW DATABASES LIKE 'DEMO_DB';

-- 2. DEMO_ROLE owns the database and warehouse --------------------------
-- READY IF: in both results, the OWNERSHIP row has grantee_name DEMO_ROLE.
-- (Owning DEMO_DB is what lets each attendee create their own schema.)
SHOW GRANTS ON DATABASE DEMO_DB;
SHOW GRANTS ON WAREHOUSE DEMO_WH;

-- 3. Sample data the dbt project reads ---------------------------------
-- READY IF: SNOWFLAKE_SAMPLE_DATA exists, and the grants include a USAGE or
-- IMPORTED PRIVILEGES row for PUBLIC or DEMO_ROLE.
-- If not: GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE_SAMPLE_DATA TO ROLE DEMO_ROLE;
SHOW DATABASES LIKE 'SNOWFLAKE_SAMPLE_DATA';
SHOW GRANTS ON DATABASE SNOWFLAKE_SAMPLE_DATA;

-- 4. CoCo Desktop: Cortex access ----------------------------------------
-- READY IF: SNOWFLAKE.CORTEX_USER (or CORTEX_AGENT_USER) is granted to PUBLIC,
-- or to DEMO_ROLE. If not: GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE DEMO_ROLE;
SHOW GRANTS OF DATABASE ROLE SNOWFLAKE.CORTEX_USER;

-- 5. CoCo Desktop: cross-region inference ---------------------------------
-- READY IF: value is not DISABLED (e.g. ANY_REGION, AWS_US). CoCo Desktop requires it.
-- To enable (your choice of regions): ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';
SHOW PARAMETERS LIKE 'CORTEX_ENABLED_CROSS_REGION' IN ACCOUNT;

-- 6. CoCo Desktop: per-user daily credit limit -----------------------------
-- READY IF: -1 (no limit) or a positive number big enough for a 2.5-hour lab.
-- 0 blocks CoCo Desktop for everyone.
SHOW PARAMETERS LIKE 'CORTEX_CODE_DESKTOP_DAILY_EST_CREDIT_LIMIT_PER_USER' IN ACCOUNT;

-- 7. Network policy (needed for attendees' Personal Access Tokens) -------
-- PATs only work for a person user who is subject to a network policy
-- (account-level or on the user), unless an authentication policy relaxes that.
-- READY IF: an account-level NETWORK_POLICY is set, or every attendee has one,
-- and attendees connect from an allowed network (e.g. the VPN).
-- If there's no policy, attendees use the browser sign-in instead (lab Module 0, Step 6).
SHOW PARAMETERS LIKE 'NETWORK_POLICY' IN ACCOUNT;

-- 8. Authentication policies (can block PATs or browser sign-in) ---------
-- READY IF: no authentication policy applies, or each applicable policy's
-- AUTHENTICATION_METHODS includes PROGRAMMATIC_ACCESS_TOKEN (for PATs) and
-- the method attendees use for CoCo Desktop / dbt (OAUTH, SAML or PASSWORD).
-- For each row, run: DESCRIBE AUTHENTICATION POLICY <policy_db>.<policy_schema>.<policy_name>;
SELECT policy_db, policy_schema, policy_name, ref_entity_domain, ref_entity_name
FROM SNOWFLAKE.ACCOUNT_USAGE.POLICY_REFERENCES
WHERE policy_kind = 'AUTHENTICATION_POLICY';

-- 9. Every attendee is ready ----------------------------------------------
-- READY IF: every row says ok. USER_TYPE should be PERSON (or blank).
-- Fix NOT GRANTED by adding the user to scripts/admin_setup.sql and re-running it.
-- Live data (SHOW commands), so users created a minute ago show up.
SHOW USERS
->> SHOW GRANTS OF ROLE DEMO_ROLE
->> WITH attendees(username) AS (
      SELECT UPPER(column1) FROM VALUES
        ('JSMITH'),
        ('ADOE')
        -- , ('NEXT_USER')
    )
    SELECT a.username,
           IFF(u."name" IS NULL, 'MISSING: create the user', 'ok')                  AS user_exists,
           u."type"                                                                 AS user_type,
           IFF(u."name" IS NULL, '-', IFF(u."disabled" = 'true', 'DISABLED', 'ok'))   AS enabled,
           IFF(g."grantee_name" IS NULL, 'NOT GRANTED: add to admin_setup.sql', 'ok') AS has_demo_role
    FROM attendees a
    LEFT JOIN $2 u ON u."name" = a.username                                       -- SHOW USERS
    LEFT JOIN $1 g ON g."grantee_name" = a.username AND g."granted_to" = 'USER'   -- SHOW GRANTS OF ROLE
    ORDER BY 1;

-- 10. Warehouse headroom ------------------------------------------------
-- READY IF: you're happy with the size for ~30 people running dbt build at
-- once (SMALL recommended for the session) and with any resource monitor on it.
-- For the session: ALTER WAREHOUSE DEMO_WH SET WAREHOUSE_SIZE = SMALL;
SHOW WAREHOUSES LIKE 'DEMO_WH';
