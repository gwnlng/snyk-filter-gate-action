#!/usr/bin/env bash
set -euo pipefail

# Args: snyk_json_path (required), output_json
# Uses default filter at $GITHUB_ACTION_PATH/.snyk-filter/snyk.yml
SNYK_JSON_PATH="${1:-}"
OUTPUT_JSON="${2:-false}"
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

if [ "$OUTPUT_JSON" = "true" ]; then
  snyk-filter -i "$SNYK_JSON_PATH" -f "$FILTER_FILE" --json
else
  snyk-filter -i "$SNYK_JSON_PATH" -f "$FILTER_FILE"
fi
