#!/usr/bin/env bash
set -euo pipefail

# Args: snyk_json_path, output_json
# Uses default filter at $GITHUB_ACTION_PATH/.snyk-filter/snyk.yml
SNYK_JSON_PATH="${1:-}"
OUTPUT_JSON="${2:-false}"
FILTER_FILE="${GITHUB_ACTION_PATH:?}/.snyk-filter/snyk.yml"

if [ -n "$SNYK_JSON_PATH" ]; then
  if [ "$OUTPUT_JSON" = "true" ]; then
    snyk-filter -i "$SNYK_JSON_PATH" -f "$FILTER_FILE" --json
  else
    snyk-filter -i "$SNYK_JSON_PATH" -f "$FILTER_FILE"
  fi
else
  if [ "$OUTPUT_JSON" = "true" ]; then
    snyk-filter -f "$FILTER_FILE" --json
  else
    snyk-filter -f "$FILTER_FILE"
  fi
fi
