-- =====================================================================
-- Part 2 (optional): admin extras for the automation showcase
--
-- Each block is independent. Skip any or all; without them the
-- facilitator demos those modules instead. Run as ACCOUNTADMIN.
-- =====================================================================

-- A3 (access review) and A6 (warehouse right-sizing) -------------------
-- Read-only, but SENSITIVE: sees account-wide users, grants, login history
-- and all query text. Grant only to Snowflake admins / security owners.
USE ROLE ACCOUNTADMIN;
CREATE ROLE IF NOT EXISTS DEMO_REVIEWER
  COMMENT = 'CoCo DE workshop: read-only account metadata for A3/A6. Drop after the workshop.';
GRANT ROLE DEMO_REVIEWER TO ROLE SECURITYADMIN;
GRANT DATABASE ROLE SNOWFLAKE.SECURITY_VIEWER   TO ROLE DEMO_REVIEWER;  -- users, roles, grants, logins
GRANT DATABASE ROLE SNOWFLAKE.USAGE_VIEWER      TO ROLE DEMO_REVIEWER;  -- warehouse metering / load history
GRANT DATABASE ROLE SNOWFLAKE.GOVERNANCE_VIEWER TO ROLE DEMO_REVIEWER;  -- query history, query metering
GRANT DATABASE ROLE SNOWFLAKE.OBJECT_VIEWER     TO ROLE DEMO_REVIEWER;  -- object metadata
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER       TO ROLE DEMO_REVIEWER;
GRANT USAGE ON WAREHOUSE DEMO_WH TO ROLE DEMO_REVIEWER;
GRANT MONITOR USAGE ON ACCOUNT TO ROLE DEMO_REVIEWER;                   -- SHOW WAREHOUSES / usage across the account
-- GRANT ROLE DEMO_REVIEWER TO USER "<ADMIN_OR_FACILITATOR_USERNAME>";

-- A4 (KPI report email) -------------------------------------------------
-- Can only send to the listed, verified email addresses of users in this account.
-- CREATE NOTIFICATION INTEGRATION IF NOT EXISTS DEMO_EMAIL_INT
--   TYPE = EMAIL ENABLED = TRUE ALLOWED_RECIPIENTS = ('first.last@example.com')
--   COMMENT = 'CoCo DE workshop KPI email. Drop after the workshop.';
-- GRANT USAGE ON INTEGRATION DEMO_EMAIL_INT TO ROLE DEMO_ROLE;

-- A6 (Adaptive Warehouses facilitator demo) -----------------------------
-- Enterprise Edition and supported regions only. Never used for real work;
-- the facilitator converts it and rolls it back.
-- CREATE WAREHOUSE IF NOT EXISTS DEMO_ADAPTIVE_WH
--   WAREHOUSE_SIZE = 'XSMALL' AUTO_SUSPEND = 60 AUTO_RESUME = TRUE INITIALLY_SUSPENDED = TRUE
--   COMMENT = 'CoCo DE workshop Adaptive demo. Drop after the workshop.';

-- Cleanup after the workshop --------------------------------------------
-- DROP ROLE IF EXISTS DEMO_REVIEWER;
-- DROP INTEGRATION IF EXISTS DEMO_EMAIL_INT;
-- DROP WAREHOUSE IF EXISTS DEMO_ADAPTIVE_WH;
