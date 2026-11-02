-- =====================================================================
-- Data Engineering with CoCo: the ONE admin script for the workshop
--
-- Fill in the 3 settings below, then Run all (as ACCOUNTADMIN). Every run ends
-- with the same readiness report: check_no | item | status | detail | how_to_fix,
-- with OVERALL on the first row.
--
--   1. RUN_MODE = 'CHECK'   -> read-only report. See what's missing. Changes nothing.
--   2. RUN_MODE = 'SETUP'   -> creates DEMO_ROLE / DEMO_WH / DEMO_DB, grants
--                              DEMO_ROLE to the attendees (and, if CI_PATH_A = 'YES',
--                              lets GitHub Actions in for them), then shows the report.
--                              Ready when OVERALL = READY. Safe to re-run any time,
--                              e.g. after adding attendees or the day before the lab.
--   3. RUN_MODE = 'CLEANUP' -> after the workshop: removes the CI network policy
--                              from the attendees. To drop the lab objects too, see
--                              the bottom of this file.
--
-- Attendees then run scripts/setup.sql on the day: it creates only their own
-- schema, DEMO_DB.TPCH_<INITIALS>.
-- =====================================================================

-- ---------------------------------------------------------------- SETTINGS
SET RUN_MODE  = 'CHECK';          -- 'CHECK', 'SETUP' or 'CLEANUP'
SET CI_PATH_A = 'NO';             -- 'YES' = let GitHub Actions runners reach Snowflake for the
                                  -- attendees (only matters if the account has a network
                                  -- policy; lab Module 4). 'NO' = attendees use the laptop fallback.
SET ATTENDEES = 'JSMITH, ADOE';   -- every attendee's Snowflake username, comma-separated.
                                  -- The only place names go. Case doesn't matter.
-- -------------------------------------------------------------------------

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;   -- any warehouse you can use (DEMO_WH may not exist yet)

EXECUTE IMMEDIATE $$
DECLARE
  run_mode   VARCHAR DEFAULT UPPER(TRIM($RUN_MODE));
  ci_path_a  BOOLEAN DEFAULT UPPER(TRIM($CI_PATH_A)) IN ('YES', 'Y', 'TRUE');
  attendees  ARRAY DEFAULT ARRAY_CONSTRUCT();
  report     ARRAY DEFAULT ARRAY_CONSTRUCT();
  actions    ARRAY DEFAULT ARRAY_CONSTRUCT();
  not_found  ARRAY DEFAULT ARRAY_CONSTRUCT();
  has_role   INT DEFAULT 0;
  has_wh     INT DEFAULT 0;
  has_db     INT DEFAULT 0;
  n          INT DEFAULT 0;
  v          VARCHAR;
  v2         VARCHAR;
  acct_np    VARCHAR;
  ip_list    VARCHAR;
  rule_list  VARCHAR;
  allowed    VARCHAR;
  granted    ARRAY DEFAULT ARRAY_CONSTRUCT();
  bad_auth   ARRAY DEFAULT ARRAY_CONSTRUCT();
  auth_count INT DEFAULT 0;
  ci_on      INT DEFAULT 0;
  ci_rule    INT DEFAULT 0;
  u          VARCHAR;
  u_exists   INT;
  u_disabled VARCHAR;
  u_type     VARCHAR;
  u_np       VARCHAR;
  txt        VARCHAR;
  res        RESULTSET;
  bad_mode   EXCEPTION (-20010, 'RUN_MODE must be CHECK, SETUP or CLEANUP.');
BEGIN
  IF (:run_mode NOT IN ('CHECK', 'SETUP', 'CLEANUP')) THEN
    RAISE bad_mode;
  END IF;

  SELECT ARRAY_AGG(DISTINCT UPPER(TRIM(value))) INTO :attendees
    FROM TABLE(SPLIT_TO_TABLE($ATTENDEES, ',')) WHERE TRIM(value) <> '';
  attendees := COALESCE(:attendees, ARRAY_CONSTRUCT());

  SHOW PARAMETERS LIKE 'NETWORK_POLICY' IN ACCOUNT;
  SELECT NULLIF(MAX("value"), '') INTO :acct_np FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

  -- ================================================================ SETUP
  -- Same objects as the guide's setup.sql, with DEMO_ROLE granted to every attendee.
  IF (:run_mode = 'SETUP') THEN
    CREATE ROLE IF NOT EXISTS DEMO_ROLE;
    GRANT ROLE DEMO_ROLE TO ROLE SYSADMIN;
    -- Shared warehouse. XSMALL works; SMALL gives ~30 people running dbt build at once more headroom.
    CREATE WAREHOUSE IF NOT EXISTS DEMO_WH WAREHOUSE_SIZE = XSMALL, AUTO_SUSPEND = 300, AUTO_RESUME = TRUE;
    GRANT OWNERSHIP ON WAREHOUSE DEMO_WH TO ROLE DEMO_ROLE COPY CURRENT GRANTS;
    -- DEMO_ROLE owns the database, so attendees can create their own schema in it.
    CREATE DATABASE IF NOT EXISTS DEMO_DB;
    GRANT OWNERSHIP ON DATABASE DEMO_DB TO ROLE DEMO_ROLE COPY CURRENT GRANTS;
    actions := ARRAY_APPEND(:actions, 'DEMO_ROLE, DEMO_WH, DEMO_DB ready');
    BEGIN
      GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE_SAMPLE_DATA TO ROLE DEMO_ROLE;
      actions := ARRAY_APPEND(:actions, 'sample data granted');
    EXCEPTION WHEN OTHER THEN
      actions := ARRAY_APPEND(:actions, 'sample data NOT granted (see check 3)');
    END;

    FOR i IN 0 TO ARRAY_SIZE(:attendees) - 1 DO
      u := :attendees[i]::VARCHAR;
      BEGIN
        EXECUTE IMMEDIATE 'GRANT ROLE DEMO_ROLE TO USER "' || :u || '"';
        n := n + 1;
      EXCEPTION WHEN OTHER THEN
        not_found := ARRAY_APPEND(:not_found, :u);
      END;
    END FOR;
    actions := ARRAY_APPEND(:actions, 'DEMO_ROLE granted to ' || :n || ' attendee(s)');

    -- CI path A: a lab policy on the attendee users only = what the account policy allows
    -- today + GitHub's runners (Snowflake's built-in, auto-updated GITHUBACTIONS_GLOBAL rule).
    -- A user-level policy overrides the account policy for that user; the account policy is untouched.
    IF (:ci_path_a AND :acct_np IS NOT NULL) THEN
      allowed := '''SNOWFLAKE.NETWORK_SECURITY.GITHUBACTIONS_GLOBAL''';
      EXECUTE IMMEDIATE 'DESCRIBE NETWORK POLICY "' || :acct_np || '"';
      SELECT MAX(IFF("name" = 'ALLOWED_IP_LIST', "value", NULL)),
             MAX(IFF("name" = 'ALLOWED_NETWORK_RULE_LIST', "value", NULL))
        INTO :ip_list, :rule_list FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
      -- IP-list policy: copy the IPs into a rule (a policy that uses rules ignores IP lists).
      IF (:ip_list IS NOT NULL AND :ip_list <> '') THEN
        EXECUTE IMMEDIATE 'CREATE OR REPLACE NETWORK RULE DEMO_DB.PUBLIC.COCO_LAB_CORP_NETWORK MODE = INGRESS TYPE = IPV4 VALUE_LIST = (''' ||
          REPLACE(REPLACE(:ip_list, ' ', ''), ',', ''',''') ||
          ''') COMMENT = ''CoCo DE lab: copy of ' || :acct_np || ' allowed IPs. Removed by RUN_MODE = CLEANUP.''';
        allowed := :allowed || ', ''DEMO_DB.PUBLIC.COCO_LAB_CORP_NETWORK''';
      END IF;
      -- Rule-based policy: reuse its rules as they are.
      IF (:rule_list IS NOT NULL AND :rule_list <> '') THEN
        SELECT :allowed || LISTAGG(', ''' || f.value:fullyQualifiedRuleName::VARCHAR || '''', '')
          INTO :allowed FROM TABLE(FLATTEN(INPUT => PARSE_JSON(:rule_list))) f;
      END IF;
      EXECUTE IMMEDIATE 'CREATE OR REPLACE NETWORK POLICY COCO_LAB_CI_POLICY ALLOWED_NETWORK_RULE_LIST = (' ||
        :allowed || ') COMMENT = ''CoCo DE lab: company network plus GitHub Actions runners. Removed by RUN_MODE = CLEANUP.''';
      n := 0;
      FOR i IN 0 TO ARRAY_SIZE(:attendees) - 1 DO
        u := :attendees[i]::VARCHAR;
        BEGIN
          EXECUTE IMMEDIATE 'ALTER USER "' || :u || '" SET NETWORK_POLICY = COCO_LAB_CI_POLICY';
          n := n + 1;
        EXCEPTION WHEN OTHER THEN NULL;   -- already listed in not_found
        END;
      END FOR;
      actions := ARRAY_APPEND(:actions, 'CI policy (' || :acct_np || ' + GitHub runners) set on ' || :n || ' attendee(s)');
    ELSEIF (:ci_path_a) THEN
      actions := ARRAY_APPEND(:actions, 'CI policy not needed: no account network policy');
    END IF;
  END IF;

  -- ================================================================ CLEANUP
  IF (:run_mode = 'CLEANUP') THEN
    n := 0;
    FOR i IN 0 TO ARRAY_SIZE(:attendees) - 1 DO
      u := :attendees[i]::VARCHAR;
      BEGIN
        EXECUTE IMMEDIATE 'SHOW PARAMETERS LIKE ''NETWORK_POLICY'' IN USER "' || :u || '"';
        SELECT MAX(IFF("level" = 'USER', "value", NULL)) INTO :u_np FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
        IF (:u_np = 'COCO_LAB_CI_POLICY') THEN
          EXECUTE IMMEDIATE 'ALTER USER "' || :u || '" UNSET NETWORK_POLICY';
          n := n + 1;
        END IF;
      EXCEPTION WHEN OTHER THEN NULL;
      END;
    END FOR;
    BEGIN
      DROP NETWORK POLICY IF EXISTS COCO_LAB_CI_POLICY;
      DROP NETWORK RULE IF EXISTS DEMO_DB.PUBLIC.COCO_LAB_CORP_NETWORK;
      actions := ARRAY_APPEND(:actions, 'CI policy removed from ' || :n || ' attendee(s) and dropped');
    EXCEPTION WHEN OTHER THEN
      actions := ARRAY_APPEND(:actions, 'CI policy removed from ' || :n || ' attendee(s); could not drop it (still set on a user not in ATTENDEES?): ' || SQLERRM);
    END;
  END IF;

  IF (ARRAY_SIZE(:actions) > 0) THEN
    report := ARRAY_APPEND(:report, OBJECT_CONSTRUCT(
      'n', 0, 'item', :run_mode || ' actions', 'status', 'DONE',
      'detail', ARRAY_TO_STRING(:actions, '; ') ||
                IFF(ARRAY_SIZE(:not_found) > 0, '; NOT FOUND, check spelling: ' || ARRAY_TO_STRING(:not_found, ', '), ''),
      'fix', ''));
  END IF;

  -- ================================================================ READINESS REPORT (read-only)
  -- 1. Shared workshop objects
  SHOW ROLES LIKE 'DEMO_ROLE';
  SELECT COUNT(*) INTO :has_role FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
  SHOW WAREHOUSES LIKE 'DEMO_WH';
  SELECT COUNT(*) INTO :has_wh FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
  SHOW DATABASES LIKE 'DEMO_DB';
  SELECT COUNT(*) INTO :has_db FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
  report := ARRAY_APPEND(:report, OBJECT_CONSTRUCT(
    'n', 1, 'item', 'Shared objects DEMO_ROLE, DEMO_WH, DEMO_DB',
    'status', IFF(:has_role + :has_wh + :has_db = 3, 'READY', 'FIX'),
    'detail', 'DEMO_ROLE ' || IFF(:has_role > 0, 'exists', 'missing') || ', DEMO_WH ' || IFF(:has_wh > 0, 'exists', 'missing') || ', DEMO_DB ' || IFF(:has_db > 0, 'exists', 'missing'),
    'fix', IFF(:has_role + :has_wh + :has_db = 3, '', 'Run this script with RUN_MODE = ''SETUP''')));

  -- 2. DEMO_ROLE owns DEMO_DB and DEMO_WH (lets attendees create their own schema)
  v := NULL; v2 := NULL;
  IF (:has_db > 0) THEN
    SHOW GRANTS ON DATABASE DEMO_DB;
    SELECT MAX(IFF("privilege" = 'OWNERSHIP', "grantee_name", NULL)) INTO :v FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
  END IF;
  IF (:has_wh > 0) THEN
    SHOW GRANTS ON WAREHOUSE DEMO_WH;
    SELECT MAX(IFF("privilege" = 'OWNERSHIP', "grantee_name", NULL)) INTO :v2 FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
  END IF;
  report := ARRAY_APPEND(:report, OBJECT_CONSTRUCT(
    'n', 2, 'item', 'DEMO_ROLE owns DEMO_DB and DEMO_WH',
    'status', IFF(:v = 'DEMO_ROLE' AND :v2 = 'DEMO_ROLE', 'READY', 'FIX'),
    'detail', 'DEMO_DB owner: ' || COALESCE(:v, '-') || ', DEMO_WH owner: ' || COALESCE(:v2, '-'),
    'fix', IFF(:v = 'DEMO_ROLE' AND :v2 = 'DEMO_ROLE', '', 'Run this script with RUN_MODE = ''SETUP'' (transfers ownership, keeps existing grants)')));

  -- 3. Sample data the dbt project reads
  BEGIN
    SHOW GRANTS ON DATABASE SNOWFLAKE_SAMPLE_DATA;
    SELECT COUNT(*) INTO :n FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
      WHERE "grantee_name" IN ('PUBLIC', 'DEMO_ROLE') AND "privilege" IN ('USAGE', 'IMPORTED PRIVILEGES');
  EXCEPTION WHEN OTHER THEN n := -1;
  END;
  report := ARRAY_APPEND(:report, OBJECT_CONSTRUCT(
    'n', 3, 'item', 'SNOWFLAKE_SAMPLE_DATA readable by DEMO_ROLE',
    'status', IFF(:n > 0, 'READY', 'FIX'),
    'detail', IFF(:n = -1, 'SNOWFLAKE_SAMPLE_DATA database not found', IFF(:n > 0, 'granted to PUBLIC or DEMO_ROLE', 'no grant to PUBLIC or DEMO_ROLE')),
    'fix', IFF(:n > 0, '', IFF(:n = -1, 'Create it from the Snowflake share (Data Products > Private Sharing), then run SETUP', 'Run this script with RUN_MODE = ''SETUP'''))));

  -- 4. Cortex access for CoCo Desktop
  SHOW GRANTS OF DATABASE ROLE SNOWFLAKE.CORTEX_USER;
  SELECT COUNT(*) INTO :n FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())) WHERE "grantee_name" IN ('PUBLIC', 'DEMO_ROLE');
  report := ARRAY_APPEND(:report, OBJECT_CONSTRUCT(
    'n', 4, 'item', 'SNOWFLAKE.CORTEX_USER granted to PUBLIC or DEMO_ROLE',
    'status', IFF(:n > 0, 'READY', 'FIX'),
    'detail', IFF(:n > 0, 'granted', 'not granted to PUBLIC or DEMO_ROLE'),
    'fix', IFF(:n > 0, '', 'GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE DEMO_ROLE;')));

  -- 5. Cross-region inference (CoCo Desktop requires it)
  SHOW PARAMETERS LIKE 'CORTEX_ENABLED_CROSS_REGION' IN ACCOUNT;
  SELECT MAX("value") INTO :v FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
  report := ARRAY_APPEND(:report, OBJECT_CONSTRUCT(
    'n', 5, 'item', 'Cross-region inference enabled',
    'status', IFF(:v <> 'DISABLED', 'READY', 'FIX'),
    'detail', 'CORTEX_ENABLED_CROSS_REGION = ' || COALESCE(:v, '-'),
    'fix', IFF(:v <> 'DISABLED', '', 'ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = ''ANY_REGION''; (or the regions you allow)')));

  -- 6. Per-user daily CoCo Desktop credit limit
  SHOW PARAMETERS LIKE 'CORTEX_CODE_DESKTOP_DAILY_EST_CREDIT_LIMIT_PER_USER' IN ACCOUNT;
  SELECT MAX("value") INTO :v FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
  report := ARRAY_APPEND(:report, OBJECT_CONSTRUCT(
    'n', 6, 'item', 'CoCo Desktop daily credit limit per user',
    'status', IFF(:v = '0', 'FIX', IFF(:v = '-1' OR :v IS NULL, 'READY', 'REVIEW')),
    'detail', 'limit = ' || COALESCE(:v, 'not set') || IFF(:v = '-1', ' (no limit)', ''),
    'fix', IFF(:v = '0', '0 blocks CoCo Desktop for everyone. Set -1 or a value that covers a 2.5-hour lab',
           IFF(:v = '-1' OR :v IS NULL, '', 'Confirm the limit covers a 2.5-hour lab'))));

  -- 7. Network policy (attendees' dbt tokens need one)
  report := ARRAY_APPEND(:report, OBJECT_CONSTRUCT(
    'n', 7, 'item', 'Account network policy',
    'status', 'REVIEW',
    'detail', IFF(:acct_np IS NULL, 'none set', :acct_np),
    'fix', IFF(:acct_np IS NULL,
      'PATs need a network policy on the user or account. Without one, attendees use browser sign-in (lab Module 0, Step 6)',
      'Attendees must connect from a network this policy allows (e.g. the VPN). See check 11 for CI')));

  -- 8. Authentication policies (must allow PATs)
  LET pols CURSOR FOR
    SELECT DISTINCT policy_db || '.' || policy_schema || '.' || policy_name AS fqn
    FROM SNOWFLAKE.ACCOUNT_USAGE.POLICY_REFERENCES
    WHERE policy_kind = 'AUTHENTICATION_POLICY';
  FOR p IN pols DO
    auth_count := auth_count + 1;
    BEGIN
      EXECUTE IMMEDIATE 'DESCRIBE AUTHENTICATION POLICY ' || p.fqn;
      SELECT MAX(IFF("property" = 'AUTHENTICATION_METHODS', "value", NULL)) INTO :v FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
      IF (NOT (:v ILIKE '%ALL%' OR :v ILIKE '%PROGRAMMATIC_ACCESS_TOKEN%')) THEN
        bad_auth := ARRAY_APPEND(:bad_auth, p.fqn || ' (' || :v || ')');
      END IF;
    EXCEPTION WHEN OTHER THEN
      bad_auth := ARRAY_APPEND(:bad_auth, p.fqn || ' (could not describe)');
    END;
  END FOR;
  report := ARRAY_APPEND(:report, OBJECT_CONSTRUCT(
    'n', 8, 'item', 'Authentication policies allow PATs',
    'status', IFF(ARRAY_SIZE(:bad_auth) = 0, 'READY', 'FIX'),
    'detail', IFF(:auth_count = 0, 'no authentication policies',
              :auth_count || ' policy(ies) checked' || IFF(ARRAY_SIZE(:bad_auth) > 0, '; missing PROGRAMMATIC_ACCESS_TOKEN: ' || ARRAY_TO_STRING(:bad_auth, ', '), '')),
    'fix', IFF(ARRAY_SIZE(:bad_auth) = 0, '', 'Add PROGRAMMATIC_ACCESS_TOKEN to AUTHENTICATION_METHODS, or attendees use browser sign-in')));

  -- 9. Every attendee: exists, enabled, PERSON, has DEMO_ROLE
  IF (:has_role > 0) THEN
    SHOW GRANTS OF ROLE DEMO_ROLE;
    SELECT ARRAY_AGG("grantee_name") INTO :granted FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())) WHERE "granted_to" = 'USER';
    granted := COALESCE(:granted, ARRAY_CONSTRUCT());
  END IF;
  IF (ARRAY_SIZE(:attendees) = 0) THEN
    report := ARRAY_APPEND(:report, OBJECT_CONSTRUCT(
      'n', 9, 'item', 'Attendees', 'status', 'FIX', 'detail', 'ATTENDEES is empty',
      'fix', 'List every attendee''s username in SET ATTENDEES at the top'));
  END IF;
  FOR i IN 0 TO ARRAY_SIZE(:attendees) - 1 DO
    u := :attendees[i]::VARCHAR;
    EXECUTE IMMEDIATE 'SHOW USERS LIKE ''' || REPLACE(:u, '''', '''''') || '''';
    SELECT COUNT(*), MAX("disabled"), MAX("type") INTO :u_exists, :u_disabled, :u_type
      FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())) WHERE "name" = :u;
    u_np := NULL;
    IF (:u_exists > 0) THEN
      EXECUTE IMMEDIATE 'SHOW PARAMETERS LIKE ''NETWORK_POLICY'' IN USER "' || :u || '"';
      SELECT MAX(IFF("level" = 'USER', "value", NULL)) INTO :u_np FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
      IF (:u_np = 'COCO_LAB_CI_POLICY') THEN ci_on := ci_on + 1; END IF;
    END IF;
    report := ARRAY_APPEND(:report, OBJECT_CONSTRUCT(
      'n', 9, 'item', 'Attendee ' || :u,
      'status', IFF(:u_exists > 0 AND :u_disabled = 'false' AND ARRAY_CONTAINS(:u::VARIANT, :granted)
                    AND COALESCE(:u_type, 'PERSON') IN ('PERSON', 'NULL', ''), 'READY', 'FIX'),
      'detail', IFF(:u_exists = 0, 'user not found',
                'type ' || COALESCE(NULLIF(:u_type, ''), 'PERSON (default)') || ', ' ||
                IFF(:u_disabled = 'true', 'DISABLED', 'enabled') || ', ' ||
                IFF(ARRAY_CONTAINS(:u::VARIANT, :granted), 'has DEMO_ROLE', 'no DEMO_ROLE') ||
                IFF(:u_np IS NOT NULL, ', user network policy ' || :u_np, '')),
      'fix', IFF(:u_exists = 0, 'Create the user, or fix the spelling in ATTENDEES',
             IFF(:u_disabled = 'true', 'ALTER USER "' || :u || '" SET DISABLED = FALSE;',
             IFF(NOT ARRAY_CONTAINS(:u::VARIANT, :granted), 'Run this script with RUN_MODE = ''SETUP''',
             IFF(COALESCE(:u_type, 'PERSON') NOT IN ('PERSON', 'NULL', ''), 'Service users can''t use the lab sign-in; use a PERSON user', ''))))));
  END FOR;

  -- 10. Warehouse size
  v := NULL;
  IF (:has_wh > 0) THEN
    SHOW WAREHOUSES LIKE 'DEMO_WH';
    SELECT MAX("size") || ', resource monitor: ' || COALESCE(NULLIF(MAX("resource_monitor"), 'null'), 'none')
      INTO :v FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
  END IF;
  report := ARRAY_APPEND(:report, OBJECT_CONSTRUCT(
    'n', 10, 'item', 'DEMO_WH size for ~30 people',
    'status', IFF(:has_wh > 0, 'REVIEW', 'FIX'),
    'detail', COALESCE(:v, 'DEMO_WH missing'),
    'fix', IFF(:has_wh > 0, 'SMALL recommended for the session: ALTER WAREHOUSE DEMO_WH SET WAREHOUSE_SIZE = SMALL;', 'Run this script with RUN_MODE = ''SETUP''')));

  -- 11. Module 4 CI: can GitHub Actions reach Snowflake?
  SHOW NETWORK RULES LIKE 'GITHUBACTIONS_GLOBAL' IN SCHEMA SNOWFLAKE.NETWORK_SECURITY;
  SELECT COUNT(*) INTO :ci_rule FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
  report := ARRAY_APPEND(:report, OBJECT_CONSTRUCT(
    'n', 11, 'item', 'Module 4 CI: GitHub Actions can reach Snowflake',
    'status', IFF(:acct_np IS NULL OR (ARRAY_SIZE(:attendees) > 0 AND :ci_on = ARRAY_SIZE(:attendees)), 'READY', 'REVIEW'),
    'detail', IFF(:acct_np IS NULL, 'no account network policy, so GitHub runners are not blocked',
              :ci_on || ' of ' || ARRAY_SIZE(:attendees) || ' attendees on COCO_LAB_CI_POLICY; GITHUBACTIONS_GLOBAL rule ' || IFF(:ci_rule > 0, 'available', 'NOT available in this region')),
    'fix', IFF(:acct_np IS NULL OR (ARRAY_SIZE(:attendees) > 0 AND :ci_on = ARRAY_SIZE(:attendees)), '',
           'Path A: set CI_PATH_A = ''YES'' and run SETUP. Path B: no change, attendees use the Module 4 laptop fallback')));

  -- Verdict on top
  txt := TO_JSON(:report);
  SELECT COUNT_IF(f.value:status::VARCHAR = 'FIX'), COUNT_IF(f.value:status::VARCHAR = 'REVIEW')
    INTO :n, :u_exists FROM TABLE(FLATTEN(INPUT => PARSE_JSON(:txt))) f;
  report := ARRAY_PREPEND(:report, OBJECT_CONSTRUCT(
    'n', 0, 'item', 'OVERALL',
    'status', IFF(:n = 0, 'READY', 'NOT READY'),
    'detail', :n || ' to fix, ' || :u_exists || ' to review',
    'fix', IFF(:n = 0, 'Ready for the lab. Look over the REVIEW rows.',
           IFF(:run_mode = 'CHECK', 'Expected before SETUP. Fix the FIX rows (most are fixed by RUN_MODE = ''SETUP''), then run again',
               'Fix the FIX rows, then run again'))));

  txt := TO_JSON(:report);
  res := (SELECT f.value:n::INT        AS check_no,
                 f.value:item::VARCHAR   AS item,
                 f.value:status::VARCHAR AS status,
                 f.value:detail::VARCHAR AS detail,
                 f.value:fix::VARCHAR    AS how_to_fix
          FROM TABLE(FLATTEN(INPUT => PARSE_JSON(:txt))) f
          ORDER BY f.index);
  RETURN TABLE(res);
END;
$$;

-- =====================================================================
-- After the workshop, once RUN_MODE = 'CLEANUP' has run: drop the lab objects.
-- Check first that nothing else lives in DEMO_DB, and keep DEMO_ROLE if it's used elsewhere.
-- =====================================================================
-- SHOW SCHEMAS IN DATABASE DEMO_DB;
-- DROP DATABASE DEMO_DB;
-- DROP WAREHOUSE DEMO_WH;
-- DROP ROLE DEMO_ROLE;
