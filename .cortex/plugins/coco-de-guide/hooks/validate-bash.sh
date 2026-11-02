#!/usr/bin/env bash
input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')
if echo "$command" | grep -Eq 'dbt[[:space:]].*--target[[:space:]=]+prod'; then
  echo "Blocked: direct production dbt runs are not allowed. Use the CI/CD pipeline instead." >&2
  exit 2
fi
exit 0
