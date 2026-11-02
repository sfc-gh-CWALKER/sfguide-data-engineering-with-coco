-- =====================================================================
-- Data Engineering with CoCo: one-time admin setup for a workshop
--
-- Run once, as ACCOUNTADMIN (or SYSADMIN + SECURITYADMIN), before the
-- workshop. Then each participant runs scripts/setup.sql, which creates
-- only their own schema DEMO_DB.TPCH_<INITIALS>.
--
-- These are the same objects as the original guide's setup.sql, with
-- DEMO_ROLE granted to every participant instead of just CURRENT_USER().
-- Safe to re-run.
-- =====================================================================

USE ROLE ACCOUNTADMIN;

-- Roles
CREATE ROLE IF NOT EXISTS DEMO_ROLE;
GRANT ROLE DEMO_ROLE TO ROLE SYSADMIN;

-- Warehouses
-- Shared by every participant. XSMALL works; SMALL gives 30 people
-- running dbt build at the same moment more headroom. Resize after.
CREATE WAREHOUSE IF NOT EXISTS DEMO_WH WAREHOUSE_SIZE = XSMALL, AUTO_SUSPEND = 300, AUTO_RESUME= TRUE;
GRANT OWNERSHIP ON WAREHOUSE DEMO_WH TO ROLE DEMO_ROLE COPY CURRENT GRANTS;
-- ALTER WAREHOUSE DEMO_WH SET WAREHOUSE_SIZE = SMALL;

-- Databases
-- DEMO_ROLE owns the database, so participants can create their own schema in it.
CREATE DATABASE IF NOT EXISTS DEMO_DB;
GRANT OWNERSHIP ON DATABASE DEMO_DB TO ROLE DEMO_ROLE COPY CURRENT GRANTS;

-- Sample data used by the dbt project (already granted to PUBLIC on most accounts)
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE_SAMPLE_DATA TO ROLE DEMO_ROLE;

-- Participants: add every attendee's Snowflake username
EXECUTE IMMEDIATE $$
DECLARE
  users ARRAY DEFAULT ARRAY_CONSTRUCT(
    'JSMITH',
    'ADOE'
    -- , 'NEXT_USER', ...
  );
  granted ARRAY DEFAULT ARRAY_CONSTRUCT();
  user_name VARCHAR;
BEGIN
  FOR i IN 0 TO ARRAY_SIZE(:users) - 1 DO
    user_name := UPPER(GET(:users, :i)::VARCHAR);
    EXECUTE IMMEDIATE 'GRANT ROLE DEMO_ROLE TO USER "' || :user_name || '"';
    granted := ARRAY_APPEND(:granted, :user_name);
  END FOR;
  RETURN 'DEMO_ROLE granted to: ' || ARRAY_TO_STRING(:granted, ', ');
END;
$$;

-- Check
SHOW GRANTS OF ROLE DEMO_ROLE;

-- ---------------------------------------------------------------------
-- After the workshop: list everyone's schemas, then clean up.
-- ---------------------------------------------------------------------
-- SHOW SCHEMAS LIKE 'TPCH_%' IN DATABASE DEMO_DB;
-- DROP DATABASE DEMO_DB;
-- DROP WAREHOUSE DEMO_WH;
-- DROP ROLE DEMO_ROLE;
