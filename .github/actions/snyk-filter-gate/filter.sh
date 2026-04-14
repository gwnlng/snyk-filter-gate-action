#!/usr/bin/env bash
set -euo pipefail

# Args: snyk_json_path (required), output_json_path (optional, default: snyk-filter-results.json in cwd)
# Uses default filter at $GITHUB_ACTION_PATH/.snyk-filter/snyk.yml
# Writes snyk-filter JSON to output_json_path.
SNYK_JSON_PATH="${1:-}"
OUTPUT_JSON_PATH="${2:-snyk-filter-results.json}"
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

# Run filter and save to output file
set +e
snyk-filter -i "$SNYK_JSON_PATH" -f "$FILTER_FILE" --json > "$OUTPUT_JSON_PATH"
FILTER_EXIT=$?
set -e

exit $FILTER_EXIT
