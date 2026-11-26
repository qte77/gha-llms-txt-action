#!/usr/bin/env bats

# Infra tests — validate action scaffold exists and is well-formed

@test "action.yml exists" {
  [ -f action.yml ]
}

@test "action.yml has name field" {
  grep -q "^name:" action.yml
}

@test "action.yml has description field" {
  grep -q "^description:" action.yml
}

@test "action.yml has branding" {
  grep -q "^branding:" action.yml
}

@test "action.yml has runs.using composite" {
  grep -q "using:.*composite" action.yml
}

@test "action.yml has template_path input" {
  grep -q "template_path:" action.yml
}

@test "action.yml has output_path input" {
  grep -q "output_path:" action.yml
}

@test "action.yml has github_token input" {
  grep -q "github_token:" action.yml
}

@test "action.yml has validate_links step" {
  grep -q "Validate template links" action.yml
}

@test "action.yml has envsubst call" {
  grep -q "envsubst" action.yml
}

@test "action.yml has derive_from_frontmatter input defaulting to false" {
  grep -q "derive_from_frontmatter:" action.yml
  grep -A3 "derive_from_frontmatter:" action.yml | grep -q 'default: "false"'
}

@test "action.yml has Resolve frontmatter placeholders step" {
  grep -q "Resolve frontmatter placeholders" action.yml
}

@test "scripts/derive-frontmatter.sh exists" {
  [ -f scripts/derive-frontmatter.sh ]
}

@test "README.md exists" {
  [ -f README.md ]
}

@test "README.md documents derive_from_frontmatter" {
  grep -q "derive_from_frontmatter" README.md
}

@test "LICENSE exists" {
  [ -f LICENSE ]
}

@test "CHANGELOG.md exists" {
  [ -f CHANGELOG.md ]
}
