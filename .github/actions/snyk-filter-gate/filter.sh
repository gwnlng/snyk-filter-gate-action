#!/usr/bin/env bash
set -euo pipefail

# Args: snyk_json_path (required), output_json, json_file_output (optional), error_log_output (optional)
# Uses default filter at $GITHUB_ACTION_PATH/.snyk-filter/snyk.yml
SNYK_JSON_PATH="${1:-}"
OUTPUT_JSON="${2:-false}"
JSON_FILE_OUTPUT="${3:-}"
ERROR_LOG_OUTPUT="${4:-}"
FILTER_FILE="${GITHUB_ACTION_PATH:?}/.snyk-filter/snyk.yml"

if [ -z "$SNYK_JSON_PATH" ]; then
  echo "Error: snyk-json-path is required. Provide the path to your Snyk test JSON file (e.g. snyk test --json > snyk-results.json)." >&2
  exit 1
fi

if [ ! -f "$SNYK_JSON_PATH" ]; then
  echo "Error: Snyk JSON file not found: $SNYK_JSON_PATH" >&2
  exit 1
fi

if [ ! -r "$SNYK_JSON_PATH" ]; then
  echo "Error: Snyk JSON file is not readable: $SNYK_JSON_PATH" >&2
  exit 1
fi

run_filter() {
  if [ "$OUTPUT_JSON" = "true" ]; then
    snyk-filter -i "$SNYK_JSON_PATH" -f "$FILTER_FILE" --json
  else
    snyk-filter -i "$SNYK_JSON_PATH" -f "$FILTER_FILE"
  fi
}

if [ -n "$JSON_FILE_OUTPUT" ] && [ -n "$ERROR_LOG_OUTPUT" ]; then
  run_filter > "$JSON_FILE_OUTPUT" 2> "$ERROR_LOG_OUTPUT"
elif [ -n "$JSON_FILE_OUTPUT" ]; then
  run_filter > "$JSON_FILE_OUTPUT"
elif [ -n "$ERROR_LOG_OUTPUT" ]; then
  run_filter 2> "$ERROR_LOG_OUTPUT"
else
  run_filter
fi
