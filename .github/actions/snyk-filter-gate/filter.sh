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

# Remove snyk-filter message lines (e.g. "project - No issues found after custom filtering") that break JSON.
# If we have concatenated JSON objects (}\n{), merge to },{ then wrap in [...] so jq can parse.
if [ -f "$OUTPUT_JSON_PATH" ] && [ -s "$OUTPUT_JSON_PATH" ]; then
  grep -v 'No issues found after custom filtering[[:space:]]*$' "$OUTPUT_JSON_PATH" > "${OUTPUT_JSON_PATH}.tmp" && mv "${OUTPUT_JSON_PATH}.tmp" "$OUTPUT_JSON_PATH"
  awk '
    /^}[[:space:]]*$/ {
      if (getline n > 0) {
        if (n ~ /^[[:space:]]*\{/) { printf "},"; print n; next }
        else { print; print n; next }
      }
    }
    { print }
  ' "$OUTPUT_JSON_PATH" > "${OUTPUT_JSON_PATH}.tmp" && mv "${OUTPUT_JSON_PATH}.tmp" "$OUTPUT_JSON_PATH"
  if grep -q '^},{[[:space:]]*$' "$OUTPUT_JSON_PATH" 2>/dev/null; then
    (echo '['; cat "$OUTPUT_JSON_PATH"; echo ']') > "${OUTPUT_JSON_PATH}.tmp" && mv "${OUTPUT_JSON_PATH}.tmp" "$OUTPUT_JSON_PATH"
  fi
fi

exit $FILTER_EXIT
