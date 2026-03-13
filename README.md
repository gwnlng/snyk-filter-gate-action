# snyk-filter-gate-action

GitHub Action that runs [snyk-filter](https://docs.snyk.io/developer-tools/snyk-cli/scan-and-maintain-projects-using-the-cli/cli-tools/snyk-filter) on a Snyk test generated JSON as a security gating filter based on the scan result JSON properties.

This GitHub Action determines following result based on the result of the security filtering:

- Pass security filter (exit status 0) when no vulnerabilities are filtered
- Fails security filter (exist status 1) when vulnerabilities are filtered

The final filter gating results is sent to GitHub Job Summary i.e. `GITHUB_STEP_SUMMARY` [variable](https://docs.github.com/en/actions/reference/workflows-and-actions/variables#default-environment-variables).

## Security Gate

The snyk-filter ruleset is managed in a default [snyk.yml](.github/actions/snyk-filter-gate/.snyk-filter/snyk.yml).
This gating ruleset is maintained by Application Security teams as a central CICD gating governance and control.

## Writing CICD Gating rules

See [snyk-filter sample filters](https://github.com/snyk-labs/snyk-filter/tree/master/sample-filters).

## Templating Scan Result

See JQ template [vulnerabilities-table.jq](.github/actions/snyk-filter-gate/vulnerabilities-table.jq).  

This is a JQ template to transform filtered JSON result to a markdown file. See following resources:

- [How to Transform JSON Data with jq](https://www.digitalocean.com/community/tutorials/how-to-transform-json-data-with-jq)
- [The JQ Playground](https://play.jqlang.org/)

> [!NOTE]
> GitHub Step [Job summary](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands#step-isolation-and-limits) is restricted to a maximum size of 1 MiB. <br>
> The filtered result markdown file content sent to Job summary needs to fit within this size limit.


## Usage

This snyk-filter-gate Action could be called after executing Snyk Open Source security check as:

- Composite action
- Resusable workflow

### Composite action

A `Snyk Open Source security check` step is first executed with Snyk CLI command or through a Snyk Github action to generate a `snyk-results.json`. This snyk-results JSON file is referenced by the snyk-filter-gate composite action.

#### Example call
```yaml
      # Run Snyk Open Source security scan
      - name: Snyk Open Source security check
        uses: snyk/actions/node@master
        continue-on-error: true
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          # In addition to the stdout, save the results as snyk-results.json
          args: --json-file-output=snyk-results.json

      # Run security gating
      - name: Run snyk-filter gating
        uses: gwnlng/snyk-filter-gate-action/.github/actions/snyk-filter-gate@main
        with:
          snyk-json-path: snyk-results.json
```

### Reusable workflow

A `snyk-security-check` Job is first executed with Snyk CLI command or Snyk Github action to generate a `snyk-results.json`. This snyk-results JSON file is uploaded as an artifact for the snyk-filter-gate reusable workflow.

#### Example call
```yaml
  snyk-security-check:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Run Snyk to check for vulnerabilities
        uses: snyk/actions/node@master
        continue-on-error: true
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          # In addition to the stdout, save the results as snyk-results.json
          args: --json-file-output=snyk-results.json

      - name: Upload Snyk security result
        uses: actions/upload-artifact@v4
        with:
          name: snyk-results
          path: snyk-results.json

  snyk-filter-gate:
    needs: snyk-security-check
    uses: gwnlng/snyk-filter-gate-action/.github/workflows/snyk-filter-gate.yml@main
    with:
      snyk-json-path: snyk-results
```
### Note

The `continue-on-error` set to `true` is required so that the CICD GitHub action workflow does not terminate at the Snyk security Step or Job when vulnerabilities are detected.

## Version release

Push a tag `v*` (e.g. `v1.0.0`) to create a GitHub Release.

```bash
git tag v1.0.0
git push origin v1.0.0
```

Modify the calling action steps or workflow to refer to the new tag.
