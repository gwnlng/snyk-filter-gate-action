# Usage: jq -rf severity-summary-table.jq input.json
# Outputs a Markdown table with counts grouped by severity plus a total row.

def vulnitems:
  if type == "array" then
    .[] | .vulnerabilities[]?
  else
    .vulnerabilities[]?
  end;

def severity_counts:
  [vulnitems | .severity // "unknown"]
  | group_by(.)
  | map({severity: .[0], count: length})
  | sort_by(
      (if .severity == "critical" then 0
       elif .severity == "high" then 1
       elif .severity == "medium" then 2
       elif .severity == "low" then 3
       else 4
       end)
    );

def rows:
  ["| Vulnerability by Severity | Count |", "|---|---|"]
  + (severity_counts | map("| \(.severity) | \(.count) |"))
  + ["| **Total** | **\((severity_counts | map(.count) | add // 0))** |"];

rows | join("\n")
