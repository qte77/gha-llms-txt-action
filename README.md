# gha-llms-txt-action

![Version](https://img.shields.io/badge/version-0.1.0-8A2BE2)
![License](https://img.shields.io/badge/license-Apache--2.0-blue)
![Test Action](https://github.com/qte77/gha-llms-txt-action/actions/workflows/test-action.yaml/badge.svg)
![CodeFactor](https://www.codefactor.io/repository/github/qte77/gha-llms-txt-action/badge)
![CodeQL](https://github.com/qte77/gha-llms-txt-action/actions/workflows/codeql.yaml/badge.svg)
![Dependabot](https://img.shields.io/badge/dependabot-enabled-025e8c)
![BATS](https://github.com/qte77/gha-llms-txt-action/actions/workflows/bats.yaml/badge.svg)

Composite GitHub Action that generates `llms.txt` from a template using `envsubst`, optionally opening a pull request with the results.

## Inputs

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `template_path` | no | `.github/templates/llms.txt.tpl` | Path to the llms.txt.tpl template file |
| `output_path` | no | `docs/llms.txt` | Path for the generated llms.txt output file |
| `validate_links` | no | `true` | Validate that template BLOB links point to existing files |
| `default_branch` | no | `main` | Default branch name used to construct BLOB URLs |
| `create_pr` | no | `true` | Whether to create a PR with llms.txt changes |
| `github_token` | **yes** | — | GitHub token for API access and PR creation |

## Outputs

| Name | Description |
|------|-------------|
| `changed` | Whether llms.txt changed (`true` or `false`) |
| `pr_url` | URL of the created PR (empty if no PR was created) |

## Usage

```yaml
name: Write llms.txt

on:
  push:
    branches: [main]
    paths:
      - ".github/templates/llms.txt.tpl"
      - "app/**"
      - "README.md"
  workflow_dispatch:

permissions:
  contents: write
  pull-requests: write

jobs:
  generate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      - uses: qte77/gha-llms-txt-action@v0.1.0
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
```

## Template variables

The template supports three variables via `envsubst`:

| Variable | Source |
|----------|--------|
| `${BLOB}` | `https://github.com/<repo>/blob/<default_branch>` |
| `${PROJECT_NAME}` | First H1 heading from `README.md` |
| `${PROJECT_DESC}` | GitHub API repo description |

## What it does

1. Validates the template file exists
2. Optionally checks that all `${BLOB}/path` references point to existing files
3. Substitutes template variables via `envsubst`
4. If files changed and `create_pr` is `true`, opens a PR with the update

## License

[Apache-2.0](LICENSE)
