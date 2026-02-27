# snyk-filter-gate-action

GitHub Action that runs [snyk-filter](https://github.com/snyk-labs/snyk-filter) on Snyk test JSON with a default filter (fixable + exploit).

## Testing

- **Automated:** Push or open a PR to run the [Test](.github/workflows/test.yml) workflow:
  - **Script validation** – Installs snyk-filter and runs `tests/filter-test.sh` (missing path, file not found, valid path).
  - **Action with valid JSON** – Runs the action with `tests/fixtures/snyk-sample-no-matching-vulns.json` (expect pass).
  - **Action with matching vulns** – Runs the action with `tests/fixtures/snyk-sample-with-vulns.json` (expect fail).
  - **Action without path** – Runs the action with empty `snyk-json-path` (expect error).

- **Local (optional):** From repo root, with `snyk-filter` and `jq` installed:
  ```bash
  export GITHUB_ACTION_PATH="$(pwd)/.github/actions/snyk-filter-gate"
  chmod +x tests/filter-test.sh && tests/filter-test.sh
  ```

## Version release

Push a tag `v*` (e.g. `v1.0.0`) to create a GitHub Release:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The [Release](.github/workflows/release.yml) workflow creates the release with generated notes.