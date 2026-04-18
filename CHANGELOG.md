# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

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
