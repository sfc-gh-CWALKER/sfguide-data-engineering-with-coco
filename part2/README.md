# Part 2: Automation workflows (optional)

Extras for the workshop's Part 2 showcase. Nothing here is used by Part 1:
the dbt project in `dbt/` never reads this folder, so Part 1 builds exactly
what the [Data Engineering with CoCo](https://www.snowflake.com/en/developers/guides/data-engineering-with-coco/)
guide builds.

| File | Who runs it | For |
|---|---|---|
| `resident_contacts.sql` | Each participant (set `MY_INITIALS`, then Run all) | A2: synthetic PII table in your `DEMO_DB.TPCH_<INITIALS>` schema |
| `admin_optional.sql` | Workshop admin, once | A3/A6 reviewer role, A4 email integration, A6 Adaptive demo warehouse |
| `solutions/coco-de-guide/` | Nobody, it's a reference | Finished versions of every Part 1 and Part 2 skill, subagent and hook |
| `solutions/github-workflows/pr-review.yml` | Each participant, Module 4 | Tested CI workflow: the guide's, plus installing dbt, loading the plugin, allowing tools, and failing when there's no PASS/FAIL verdict. Needs a fourth secret, `SNOWFLAKE_SCHEMA` (`TPCH_<INITIALS>`) |

To compare your plugin with the reference, look at
`part2/solutions/coco-de-guide/`. Don't copy it into `.cortex/plugins/` unless
you're stuck: building it yourself is the point of the lab.
