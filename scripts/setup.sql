-- =====================================================================
-- Data Engineering with CoCo: per-participant setup
--
-- 1. Change XX below to your initials (2-4 letters), for example 'CW'.
-- 2. Run all (down arrow next to the blue play button, or CMD/CTRL+Shift+Enter).
--
-- Your workshop admin already created the shared DEMO_ROLE, DEMO_WH and
-- DEMO_DB (scripts/admin_setup.sql). This script only creates your own
-- schema, DEMO_DB.TPCH_<YOUR_INITIALS>, so everyone in the workshop can
-- build the same dbt models without overwriting each other.
-- =====================================================================

SET MY_INITIALS = 'XX';

-- Role and warehouse (shared, created by your admin)
USE ROLE DEMO_ROLE;
USE WAREHOUSE DEMO_WH;

-- Schema (yours). Stops with an error if MY_INITIALS is still XX.
EXECUTE IMMEDIATE $$
DECLARE
  bad_initials EXCEPTION (-20001, 'Set MY_INITIALS at the top of scripts/setup.sql to your 2-4 letter initials (e.g. CW), then run the script again.');
  initials VARCHAR DEFAULT UPPER(TRIM($MY_INITIALS));
BEGIN
  IF (initials = 'XX' OR NOT REGEXP_LIKE(initials, '[A-Z]{2,4}')) THEN
    RAISE bad_initials;
  END IF;
  EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS DEMO_DB.TPCH_' || initials;
  RETURN 'Your schema DEMO_DB.TPCH_' || initials || ' is ready. Use it as the schema in ~/.dbt/profiles.yml.';
END;
$$;

-- Check: the dbt project reads this sample data (expect 1500000)
SELECT COUNT(*) AS orders FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS;
