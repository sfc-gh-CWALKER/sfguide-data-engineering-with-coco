# Data Engineering with CoCo

![DE with CoCo](/images/coco_de_logo.png)

This repository contains the code for [the Data Engineering with CoCo Snowflake Guide](https://www.snowflake.com/en/developers/guides/data-engineering-with-coco/). Please start with that Guide.

## Running it as a workshop (many people, one Snowflake account)

This fork is set up so a whole team can follow the guide at the same time
without overwriting each other's work. Everything works exactly as the guide
describes, with three differences:

1. **Your admin runs `scripts/admin_setup.sql` once.** It creates the shared
   `DEMO_ROLE`, `DEMO_WH` and `DEMO_DB` from the guide and grants `DEMO_ROLE`
   to every participant. `scripts/admin_readiness_check.sql` (read-only) then
   confirms the account and every participant are ready.
2. **You run `scripts/setup.sql` with your initials.** Change `XX` on the line
   `SET MY_INITIALS = 'XX';`, then Run all. It creates your own schema,
   `DEMO_DB.TPCH_<YOUR_INITIALS>`.
3. **Wherever the guide says `TPCH_TRANSFORMED`, use `TPCH_<YOUR_INITIALS>`.**
   That's the `schema:` line in `~/.dbt/profiles.yml` and the schema in the
   AGENTS.md prompt.

Everything else is per person already: your own PAT, your own fork for the
CI/CD section, and the plugin catalog publishes to your personal
`USER$<YOUR_USERNAME>` database.

The optional `part2/` folder has extra material for workshop automation
modules. The dbt project never reads it.

## License
Copyright (c) Snowflake Inc. All rights reserved.
Licensed under the [Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0) license.
