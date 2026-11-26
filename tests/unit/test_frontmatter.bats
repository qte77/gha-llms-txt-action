#!/usr/bin/env bats

# Behavior tests for scripts/derive-frontmatter.sh (frontmatter placeholders)

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  SCRIPT="$ROOT/scripts/derive-frontmatter.sh"
  FIX="$ROOT/tests/fixtures/frontmatter"
  # Token paths are relative to the consumer repo root, so run from the fixture dir.
  cd "$FIX"
}

@test "golden: tokens resolve from frontmatter, fallbacks fill the gaps" {
  bash "$SCRIPT" template.tpl > "$BATS_TEST_TMPDIR/out.tpl"
  cmp "$BATS_TEST_TMPDIR/out.tpl" golden.tpl
}

@test "doc without frontmatter uses the fallback, body --- block is ignored" {
  printf '%s\n' '${DOC_TITLE:docs/nofm.md|Fallback T}|${DOC_PURPOSE:docs/nofm.md|Fallback P}' > "$BATS_TEST_TMPDIR/t.tpl"
  run bash "$SCRIPT" "$BATS_TEST_TMPDIR/t.tpl"
  [ "$status" -eq 0 ]
  [ "$output" = "Fallback T|Fallback P" ]
}

@test "quoted values lose their quotes, colons and pipes inside values are kept" {
  printf '%s\n' '${DOC_TITLE:docs/quoted.md|x}' '${DOC_PURPOSE:docs/quoted.md|x}' > "$BATS_TEST_TMPDIR/t.tpl"
  run bash "$SCRIPT" "$BATS_TEST_TMPDIR/t.tpl"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "Quoted: Title & More" ]
  [ "${lines[1]}" = 'Single quoted: purpose with | pipe and $HOME' ]
}

@test "missing key falls back, no empty value is emitted" {
  printf '%s\n' '[${DOC_PURPOSE:docs/partial.md|Fallback P}]' > "$BATS_TEST_TMPDIR/t.tpl"
  run bash "$SCRIPT" "$BATS_TEST_TMPDIR/t.tpl"
  [ "$output" = "[Fallback P]" ]
}

@test "missing file falls back; token without fallback becomes empty" {
  printf '%s\n' '[${DOC_TITLE:docs/nope.md|Fallback}][${DOC_TITLE:docs/nope.md}]' > "$BATS_TEST_TMPDIR/t.tpl"
  out=$(bash "$SCRIPT" "$BATS_TEST_TMPDIR/t.tpl" 2>/dev/null)
  [ "$out" = "[Fallback][]" ]
}

@test "path outside the repo (absolute or ..) is not read, fallback used" {
  printf '%s\n' '${DOC_TITLE:/etc/hostname|A}${DOC_TITLE:../x.md|B}' > "$BATS_TEST_TMPDIR/t.tpl"
  out=$(bash "$SCRIPT" "$BATS_TEST_TMPDIR/t.tpl" 2>/dev/null)
  [ "$out" = "AB" ]
  bash "$SCRIPT" "$BATS_TEST_TMPDIR/t.tpl" 2>&1 >/dev/null | grep -q '::warning::'
}

@test "flag off: template without DOC tokens passes through byte-identical" {
  bash "$SCRIPT" plain.tpl | cmp - plain.tpl
}

@test "flag off: no trailing newline is preserved" {
  printf 'a ${BLOB} b' > "$BATS_TEST_TMPDIR/n.tpl"
  bash "$SCRIPT" "$BATS_TEST_TMPDIR/n.tpl" | cmp - "$BATS_TEST_TMPDIR/n.tpl"
}

@test "full pipeline: script then envsubst equals envsubst of golden" {
  export BLOB="https://example.test/blob/main" PROJECT_NAME="P" PROJECT_DESC="D"
  bash "$SCRIPT" template.tpl | envsubst '${BLOB} ${PROJECT_NAME} ${PROJECT_DESC}' > "$BATS_TEST_TMPDIR/out.txt"
  envsubst '${BLOB} ${PROJECT_NAME} ${PROJECT_DESC}' < golden.tpl | cmp - "$BATS_TEST_TMPDIR/out.txt"
}

@test "--list-paths prints each DOC token path once per occurrence" {
  run bash "$SCRIPT" --list-paths template.tpl
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "docs/ingest.md" ]
  [ "${lines[8]}" = "docs/missing.md" ]
  [ "${#lines[@]}" -eq 10 ]
}

@test "missing template argument or file is an error" {
  run bash "$SCRIPT"
  [ "$status" -ne 0 ]
  run bash "$SCRIPT" docs/does-not-exist.tpl
  [ "$status" -ne 0 ]
}
