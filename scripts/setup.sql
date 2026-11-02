-- =====================================================================
-- Data Engineering with CoCo: per-participant setup
--
-- 1. Change XX below to your initials (2-4 letters), for example 'CW'.
-- 2. Run all (down arrow next to the blue play button, or CMD/CTRL+Shift+Enter).
--
-- Your workshop admin already created the shared DEMO_ROLE, DEMO_WH and
-- DEMO_DB (scripts/admin_setup.sql). This script only creates your own
-- schema, DEMO_DB.TPCH_<YOUR_INITIALS>, so everyone in the workshop can
-- build the same dbt models without overwriting each other. It prints the
-- values for your dbt profile at the end.
-- =====================================================================

SET MY_INITIALS = 'XX';

-- Role and warehouse (shared, created by your admin)
USE ROLE DEMO_ROLE;
USE WAREHOUSE DEMO_WH;

-- Your schema. Stops with an error if MY_INITIALS is still XX, or if
-- another participant already uses the same initials.
EXECUTE IMMEDIATE $$
DECLARE
  bad_initials EXCEPTION (-20001, 'Set MY_INITIALS at the top of scripts/setup.sql to your 2-4 letter initials (e.g. CW), then run the script again.');
  initials_taken EXCEPTION (-20002, 'Another participant already uses these initials. Add a letter (e.g. CW -> CWA) in MY_INITIALS and run the script again. Use the same initials in the lab app.');
  initials VARCHAR DEFAULT UPPER(TRIM($MY_INITIALS));
  schema_name VARCHAR;
  claimed_by VARCHAR;
  me VARCHAR DEFAULT CURRENT_USER();
  orders INTEGER;
BEGIN
  IF (initials = 'XX' OR NOT REGEXP_LIKE(initials, '[A-Z]{2,4}')) THEN
    RAISE bad_initials;
  END IF;
  schema_name := 'TPCH_' || initials;

  -- Each schema records who created it, so two people can't share one by accident.
  SELECT MAX(COMMENT) INTO :claimed_by
    FROM DEMO_DB.INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = :schema_name;
  IF (claimed_by IS NOT NULL AND claimed_by <> 'Workshop schema for ' || me) THEN
    RAISE initials_taken;
  END IF;

  EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS DEMO_DB.' || schema_name;
  EXECUTE IMMEDIATE 'ALTER SCHEMA DEMO_DB.' || schema_name || ' SET COMMENT = ''Workshop schema for ' || me || '''';

  -- The dbt project reads this sample data.
  SELECT COUNT(*) INTO :orders FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS;

  RETURN 'Ready: DEMO_DB.' || schema_name || ' (sample data: ' || orders || ' orders). ' ||
         'For ~/.dbt/profiles.yml -> account: ' || CURRENT_ORGANIZATION_NAME() || '-' || CURRENT_ACCOUNT_NAME() ||
         '  user: ' || me || '  schema: ' || schema_name;
END;
$$;
