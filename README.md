# gha-llms-txt-action

![Version](https://img.shields.io/badge/version-0.1.0-8A2BE2)
![License](https://img.shields.io/badge/license-Apache--2.0-blue)
![Test Action](https://github.com/qte77/gha-llms-txt-action/actions/workflows/test-action.yaml/badge.svg)
![CodeFactor](https://www.codefactor.io/repository/github/qte77/gha-llms-txt-action/badge)
![CodeQL](https://github.com/qte77/gha-llms-txt-action/actions/workflows/codeql.yaml/badge.svg)
[![Dependabot Updates](https://github.com/qte77/gha-llms-txt-action/actions/workflows/dependabot/dependabot-updates/badge.svg)](https://github.com/qte77/gha-llms-txt-action/actions/workflows/dependabot/dependabot-updates)
![BATS](https://github.com/qte77/gha-llms-txt-action/actions/workflows/bats.yaml/badge.svg)

Composite GitHub Action that generates `llms.txt` from a template using `envsubst`, optionally opening a pull request with the results.

## Inputs

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `template_path` | no | `.github/templates/llms.txt.tpl` | Path to the llms.txt.tpl template file |
| `output_path` | no | `docs/llms.txt` | Path for the generated llms.txt output file |
| `validate_links` | no | `true` | Validate that template BLOB links (and `DOC_*` paths, when `derive_from_frontmatter` is `true`) point to existing files |
| `default_branch` | no | `main` | Default branch name used to construct BLOB URLs |
| `create_pr` | no | `true` | Whether to create a PR with llms.txt changes |
| `derive_from_frontmatter` | no | `false` | Resolve `${DOC_TITLE:path\|Fallback}` / `${DOC_PURPOSE:path\|Fallback}` placeholders from each file's YAML frontmatter |
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

## Frontmatter placeholders

With `derive_from_frontmatter: "true"`, link text and description can come from each document's
YAML frontmatter instead of being hard-coded in the template, so the two cannot drift:

| Placeholder | Resolves to |
|-------------|-------------|
| `${DOC_TITLE:path\|Fallback}` | `title:` of `path` |
| `${DOC_PURPOSE:path\|Fallback}` | `purpose:` of `path` |

```text
- [${DOC_TITLE:docs/ingest.md|Ingest}](${BLOB}/docs/ingest.md): ${DOC_PURPOSE:docs/ingest.md|Ingest stage overview}
```

- `path` is relative to the repository root. Absolute paths, `..` segments, unreadable files and
  paths with a symlink anywhere along them are not read.
- Only a leading `---` block counts as frontmatter: line 1 must be exactly `---` (no byte order mark,
  no trailing space). A later `---` in the body is ignored.
- Single-line values only: a block scalar (`|`, `>`) gives the fallback. If a key appears twice, the
  first one wins, even when it is empty.
- Values are inserted as written, without escaping, so a value can contain markdown (for example a
  `]` that ends the link text). They come from the repository's own files.
- Surrounding single or double quotes are stripped; values may contain `:`.
- `Fallback` is used when the file, the frontmatter or the key is missing or empty. It may not
  contain `}` or a newline. Without `|Fallback` the placeholder becomes an empty string.
- With the flag off (the default) the template is used as written, exactly as before.
- When `validate_links` is `true`, every `DOC_*` path must pass the same checks, or the step fails.

## What it does

1. Validates the template file exists
2. Optionally checks that all `${BLOB}/path` references (and `DOC_*` paths) point to existing files
3. Optionally resolves `DOC_TITLE` / `DOC_PURPOSE` placeholders from frontmatter
4. Substitutes template variables via `envsubst`
5. If files changed and `create_pr` is `true`, opens a PR with the update

## License

[Apache-2.0](LICENSE)
