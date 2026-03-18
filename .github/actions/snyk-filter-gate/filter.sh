#!/usr/bin/env bash
set -euo pipefail

# Args: snyk_json_path (required)
# Uses default filter at $GITHUB_ACTION_PATH/.snyk-filter/snyk.yml
# Writes snyk-filter stdout to snyk-filter-results.json, generates snyk-filter-results.md via jq, appends to GITHUB_STEP_SUMMARY.
SNYK_JSON_PATH="${1:-}"
FILTER_FILE="${GITHUB_ACTION_PATH:?}/.snyk-filter/snyk.yml"
JQ_TEMPLATE="${GITHUB_ACTION_PATH:?}/vulnerabilities-table.jq"
JSON_OUTPUT="snyk-filter-results.json"
MD_OUTPUT="snyk-filter-results.md"

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
  snyk-filter -i "$SNYK_JSON_PATH" -f "$FILTER_FILE" --json
}

# Run filter to temp file so $? is reliable, then tee to console and file
set +e
run_filter > "$JSON_OUTPUT.tmp"
FILTER_EXIT=$?
set -e
cat "$JSON_OUTPUT.tmp" | tee "$JSON_OUTPUT"
rm -f "$JSON_OUTPUT.tmp"

# Remove snyk-filter message lines (e.g. "project - No issues found after custom filtering") that break JSON
# If we have concatenated JSON objects (}\n{), turn them into a JSON array so jq can parse
if [ -f "$JSON_OUTPUT" ] && [ -s "$JSON_OUTPUT" ]; then
  grep -v 'No issues found after custom filtering[[:space:]]*$' "$JSON_OUTPUT" > "${JSON_OUTPUT}.tmp" && mv "${JSON_OUTPUT}.tmp" "$JSON_OUTPUT"
  awk '
    /^}[[:space:]]*$/ {
      if (getline n > 0) {
        if (n ~ /^[[:space:]]*\{/) { printf "},"; print n; next }
        else { print; print n; next }
      }
    }
    { print }
  ' "$JSON_OUTPUT" > "${JSON_OUTPUT}.tmp" && mv "${JSON_OUTPUT}.tmp" "$JSON_OUTPUT"
  if grep -q '^},{[[:space:]]*$' "$JSON_OUTPUT" 2>/dev/null; then
    (echo '['; cat "$JSON_OUTPUT"; echo ']') > "${JSON_OUTPUT}.tmp" && mv "${JSON_OUTPUT}.tmp" "$JSON_OUTPUT"
  fi
fi

# Generate markdown from JSON using jq template
if [ -f "$JSON_OUTPUT" ] && [ -s "$JSON_OUTPUT" ]; then
  jq -rf "$JQ_TEMPLATE" "$JSON_OUTPUT" > "$MD_OUTPUT" || true
  if [ -f "$MD_OUTPUT" ] && [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    cat "$MD_OUTPUT" >> "$GITHUB_STEP_SUMMARY"
  fi
fi

exit $FILTER_EXIT
