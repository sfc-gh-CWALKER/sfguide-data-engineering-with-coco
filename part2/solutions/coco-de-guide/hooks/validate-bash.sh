#!/bin/bash
# PreToolUse hook: block dbt commands that target production.
# Reads the hook context JSON on stdin; exit 2 blocks and stderr becomes the reason.
# Checks the whole input with bash + grep only, so it works without python3/jq (e.g. Windows Git Bash)
# and can only err on the side of blocking.
INPUT=$(cat)
if printf '%s' "$INPUT" | grep -Eq '(^|[^[:alnum:]_])dbt[[:space:]].*--target([[:space:]]+|=)prod([^[:alnum:]_]|$)'; then
  echo "Blocked: direct production dbt runs are not allowed from CoCo. Open a PR and let the CI/CD pipeline deploy to prod." >&2
  exit 2
fi
exit 0
