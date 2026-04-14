# Support both single object { vulnerabilities: [...] } and array of objects [ { vulnerabilities: [...] }, ... ]
# Usage: jq --arg format markdown|csv -rf vulnerabilities-table.jq input.json
# --arg format is required (pass "markdown" or "csv"; "md" is accepted as markdown).

def vulnrows:
  if type == "array" then
    .[]
    | {sourceManifest: (.displayTargetFile // ""), vulnerabilities: (.vulnerabilities // [])}
  else
    {sourceManifest: (.displayTargetFile // ""), vulnerabilities: (.vulnerabilities // [])}
  end
  | .vulnerabilities[]? as $v
  | {sourceManifest: .sourceManifest}
  + ($v // {}) ;

# Preserve row order while removing duplicate lines (especially repeated headers)
def unique_ordered:
  reduce .[] as $item ( [] ; if (. | index($item)) == null then . + [$item] else . end );

def id_cell:
  (.id // "") | if . == "" then "" else "[\(.)](https://security.snyk.io/vuln/\(.))" end;

def row:
  "| \(.sourceManifest // "") | \(.language // "") | \(.severity // "") | \(.moduleName // "") | \(.packageName // "") | \(id_cell) | \(.title // "") | \(.exploit // "") | \(.packageManager // "") | \(.name // "") | \(.version // "") | \((.fixedIn // []) | join(", ")) | \((.from // [] | .[1:] | join(" -> "))) |";

def vulnrows_array: [vulnrows];

def content_markdown:
  if (vulnrows_array | length) > 0 then
    (
      [
        "| Source Manifest | Language | Severity | Module Name | Package Name | ID | Title | Exploit | Package Manager | Name | Version | Fixed In | From |",
        "|---|---|---|---|---|---|---|---|---|---|---|---|---|"
      ]
      + (vulnrows_array | map(row))
    ) | unique_ordered | join("\n")
  else
    "No filtered vulnerabilities matching criteria found."
  end;

def csv_header:
  ["Source Manifest","Language","Severity","Module Name","Package Name","ID","Title","Exploit","Package Manager","Name","Version","Fixed In","From"]
  | @csv
  | rtrimstr("\n");

def csv_row:
  [
    (.sourceManifest // ""),
    (.language // ""),
    (.severity // ""),
    (.moduleName // ""),
    (.packageName // ""),
    (.id // ""),
    (.title // ""),
    (.exploit // ""),
    (.packageManager // ""),
    (.name // ""),
    (.version // ""),
    ((.fixedIn // []) | join(", ")),
    ((.from // [] | .[1:] | join(" -> ")))
  ]
  | @csv
  | rtrimstr("\n");

def content_csv:
  if (vulnrows_array | length) > 0 then
    (
      [csv_header]
      + (vulnrows_array | map(csv_row))
    ) | join("\n")
  else
    empty
  end;

($format | ascii_downcase) as $fmt
| if $fmt == "csv" then
    content_csv
  elif $fmt == "markdown" or $fmt == "md" then
    content_markdown
  else
    error("vulnerabilities-table: format must be \"markdown\" or \"csv\" (got: \($format))")
  end
