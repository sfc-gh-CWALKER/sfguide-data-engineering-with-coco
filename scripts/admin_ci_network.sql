-- =====================================================================
-- Data Engineering with CoCo: let GitHub Actions reach Snowflake (Module 4)
--
-- ONLY NEEDED IF your account has a network policy. Without this, the
-- Module 4 CI job is blocked (error "IP ... is not allowed to access
-- Snowflake"). Laptops on the VPN are unaffected either way.
--
-- What it does, for the listed attendees only (the account policy is untouched):
--   1. Copies the IPs/rules your account network policy allows today into a
--      network rule, so attendees can still connect from the VPN.
--   2. Adds Snowflake's built-in rule SNOWFLAKE.NETWORK_SECURITY.GITHUBACTIONS_GLOBAL
--      (GitHub's runner IPs, kept current by Snowflake).
--   3. Puts both in one policy and sets it on each attendee user.
-- A user-level policy overrides the account policy for that user only.
--
-- Run as ACCOUNTADMIN (or SECURITYADMIN). Set the two names below, list the
-- attendees, then Run all. Undo it with the CLEANUP section at the bottom.
-- If you'd rather not open GitHub's range, skip this script: attendees run the
-- same review from their laptop instead (lab Module 4, "Fallback").
-- =====================================================================

USE ROLE ACCOUNTADMIN;

SET ACCOUNT_POLICY = 'ACCOUNT_VPN_POLICY';    -- your current account network policy:
                                              -- SHOW PARAMETERS LIKE 'NETWORK_POLICY' IN ACCOUNT;
SET RULE_SCHEMA    = 'DEMO_DB.PUBLIC';        -- an existing schema to hold the lab network rule

EXECUTE IMMEDIATE $$
DECLARE
  policy_name VARCHAR DEFAULT $ACCOUNT_POLICY;
  rule_name   VARCHAR DEFAULT $RULE_SCHEMA || '.COCO_LAB_CORP_NETWORK';
  ip_list     VARCHAR;
  rule_list   VARCHAR;
  allowed     VARCHAR DEFAULT '''SNOWFLAKE.NETWORK_SECURITY.GITHUBACTIONS_GLOBAL''';
  attendees   ARRAY DEFAULT ARRAY_CONSTRUCT(
                'JSMITH',
                'ADOE'
                -- , 'NEXT_USER'
              );
  done        ARRAY DEFAULT ARRAY_CONSTRUCT();
  not_found   ARRAY DEFAULT ARRAY_CONSTRUCT();
BEGIN
  EXECUTE IMMEDIATE 'DESCRIBE NETWORK POLICY ' || :policy_name;
  SELECT MAX(IFF("name" = 'ALLOWED_IP_LIST', "value", NULL)),
         MAX(IFF("name" = 'ALLOWED_NETWORK_RULE_LIST', "value", NULL))
    INTO :ip_list, :rule_list
    FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

  -- IP-list policy: copy the IPs into a rule (a policy that uses rules ignores IP lists).
  IF (:ip_list IS NOT NULL AND :ip_list <> '') THEN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE NETWORK RULE ' || :rule_name ||
      ' MODE = INGRESS TYPE = IPV4 VALUE_LIST = (''' || REPLACE(REPLACE(:ip_list, ' ', ''), ',', ''',''') ||
      ''') COMMENT = ''CoCo DE lab: copy of ' || :policy_name || ' allowed IPs. Drop after the workshop.''';
    allowed := :allowed || ', ''' || :rule_name || '''';
  END IF;

  -- Rule-based policy: reuse its rules as they are.
  IF (:rule_list IS NOT NULL AND :rule_list <> '') THEN
    SELECT :allowed || LISTAGG(', ''' || f.value:fullyQualifiedRuleName::VARCHAR || '''', '')
      INTO :allowed
      FROM TABLE(FLATTEN(INPUT => PARSE_JSON(:rule_list))) f;
  END IF;

  EXECUTE IMMEDIATE 'CREATE OR REPLACE NETWORK POLICY COCO_LAB_CI_POLICY ALLOWED_NETWORK_RULE_LIST = (' ||
    :allowed || ') COMMENT = ''CoCo DE lab: company network plus GitHub Actions runners. Drop after the workshop.''';

  FOR i IN 0 TO ARRAY_SIZE(:attendees) - 1 DO
    LET user_name VARCHAR := UPPER(:attendees[i]::VARCHAR);
    BEGIN
      EXECUTE IMMEDIATE 'ALTER USER "' || :user_name || '" SET NETWORK_POLICY = COCO_LAB_CI_POLICY';
      done := ARRAY_APPEND(:done, :user_name);
    EXCEPTION WHEN OTHER THEN
      not_found := ARRAY_APPEND(:not_found, :user_name);
    END;
  END FOR;

  RETURN 'COCO_LAB_CI_POLICY allows: ' || :allowed ||
         '  |  set on ' || ARRAY_SIZE(:done) || ': ' || ARRAY_TO_STRING(:done, ', ') ||
         IFF(ARRAY_SIZE(:not_found) > 0, '  |  NOT FOUND, check spelling: ' || ARRAY_TO_STRING(:not_found, ', '), '');
END;
$$;

-- CHECK: the GitHub rule exists in your region (expect one row, IPV4, INGRESS).
SHOW NETWORK RULES LIKE 'GITHUBACTIONS_GLOBAL' IN SCHEMA SNOWFLAKE.NETWORK_SECURITY;

-- CHECK: spot-check an attendee (expect value COCO_LAB_CI_POLICY, level USER).
SHOW PARAMETERS LIKE 'NETWORK_POLICY' IN USER JSMITH;

-- CHECK (on the day): the Module 4 GitHub run for one attendee posts a
-- PASS/FAIL table on their PR. Snowflake-side view of that sign-in:
-- SELECT event_timestamp, client_ip, is_success, error_message
-- FROM TABLE(DEMO_DB.INFORMATION_SCHEMA.LOGIN_HISTORY_BY_USER(USER_NAME => 'JSMITH'))
-- ORDER BY event_timestamp DESC LIMIT 10;


-- =====================================================================
-- CLEANUP (after the workshop): attendees fall back to the account policy.
-- Uncomment and run. Unset the policy on every attendee first, or the DROP fails.
-- =====================================================================
-- ALTER USER JSMITH UNSET NETWORK_POLICY;
-- ALTER USER ADOE   UNSET NETWORK_POLICY;
-- DROP NETWORK POLICY COCO_LAB_CI_POLICY;
-- DROP NETWORK RULE DEMO_DB.PUBLIC.COCO_LAB_CORP_NETWORK;   -- only exists for IP-list policies
