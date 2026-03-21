# Support both single object { vulnerabilities: [...] } and array of objects [ { vulnerabilities: [...] }, ... ]
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

def row:
  "| \(.sourceManifest // "") | \(.language // "") | \(.severity // "") | \(.moduleName // "") | \(.packageName // "") | \(.id // "") | \(.title // "") | \(.exploit // "") | \(.packageManager // "") | \(.name // "") | \(.version // "") | \((.fixedIn // []) | join(", ")) | \((.from // [] | .[1:] | join(" -> "))) |";

def vulnrows_array: [vulnrows];

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
end
