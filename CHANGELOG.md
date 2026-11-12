# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Release workflows as thin callers of the `qte77/.github` reusables: `bump-version` (dispatch, opens a signed bump PR), `tag-release` (tags `vX.Y.Z` when the `pyproject.toml` version changes on `main`) and `publish-release` (dispatch, GitHub Release from the CHANGELOG block); none of them delete or overwrite tags or releases (#16)
- `.github/workflows/lint-actions.yml`: adopt the shared `qte77/.github` reusable `lint-actions` gate (actionlint + yamllint + zizmor) on push/PR/dispatch to `main` (#17)

### Changed

- Release workflows re-pinned to `qte77/.github@43ad121`. `tag-release` now also publishes the GitHub Release for a new tag in the same run, chained on the reusable's new `tag` output, so a merged bump no longer needs a manual `publish-release` dispatch (it stays as a retry). Upstream, the bump commit is now created through `createCommitOnBranch`, so GitHub signs it; the new optional App-token inputs stay unset.

### Security

- Pinned every remaining `uses:` ref in `.github/workflows/*` to its commit SHA (`actions/checkout@v7`, `github/codeql-action/{init,analyze}@v4`); the `qte77/.github` reusable callers were already SHA-pinned. No version changes.
- `.github/dependabot.yml`: grouped `github-actions` updates (`github-codeql-action`, `actions-security-updates`, `actions-version-updates` with major bumps left ungrouped) so routine Actions bumps land as fewer, reviewable PRs.
- `bats.yaml`, `codeql.yaml`, `test-action.yaml`: set `persist-credentials: false` on `actions/checkout`, surfaced by the new zizmor gate (`artipacked`); none of these jobs push back to the repo.

## [0.1.0] - 2026-04-19

### Added

- Composite GitHub Action for llms.txt generation from templates
- Template variable substitution via envsubst: BLOB, PROJECT_NAME, PROJECT_DESC
- Template link validation (checks BLOB paths exist in repo)
- Optional PR creation with llms.txt updates
- Configurable inputs: template_path, output_path, validate_links, default_branch, create_pr, github_token
- BATS infra tests for action scaffold validation
- CodeQL security scanning workflow
- BATS CI workflow
- Manual test workflow for action validation
