# Support both single object { vulnerabilities: [...] } and array of objects [ { vulnerabilities: [...] }, ... ]
def vulnerabilities:
  if type == "array" then [.[] | .vulnerabilities // []] | add
  else .vulnerabilities // []
  end;

if (vulnerabilities | length) > 0 then
  [
    "| Language | Severity | Module Name | Package Name | ID | Title | Exploit | Package Manager | Name | Version | Fixed In |",
    "|---|---|---|---|---|---|---|---|---|---|---|",
    (vulnerabilities[] | "| \(.language // "") | \(.severity // "") | \(.moduleName // "") | \(.packageName // "") | \(.id // "") | \(.title // "") | \(.exploit // "") | \(.packageManager // "") | \(.name // "") | \(.version // "") | \((.fixedIn // []) | join(", ")) |")
  ] |
  join("\n")
else
  "No filtered vulnerabilities matching criteria found."
end
