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

@test "--check-paths: template whose DOC paths are all readable passes silently" {
  printf '%s\n' '${DOC_TITLE:docs/ingest.md|a}${DOC_PURPOSE:docs/quoted.md|b}' > "$BATS_TEST_TMPDIR/t.tpl"
  run bash "$SCRIPT" --check-paths "$BATS_TEST_TMPDIR/t.tpl"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "--check-paths: refuses what the resolver refuses, one error per path, exit 1" {
  run bash "$SCRIPT" --check-paths template.tpl
  [ "$status" -eq 1 ]
  [[ "$output" == *"::error::"*"docs/missing.md"* ]]
  printf '%s\n' '${DOC_TITLE:/etc/hostname|a}${DOC_TITLE:../x.md|b}' > "$BATS_TEST_TMPDIR/t.tpl"
  run bash "$SCRIPT" --check-paths "$BATS_TEST_TMPDIR/t.tpl"
  [ "$status" -eq 1 ]
  [ "$(grep -c '::error::' <<< "$output")" -eq 2 ]
}

# Symlinks: a scratch tree with a real file, a file symlink and a directory symlink.
make_link_tree() {
  W="$BATS_TEST_TMPDIR/w"
  mkdir -p "$W/docs/real"
  printf -- '---\ntitle: Target\n---\n' > "$W/docs/real/s.md"
  ln -s real/s.md "$W/docs/link.md"
  ln -s real "$W/docs/dirlink"
  cd "$W"
}

@test "symlink as the file is not read, fallback used" {
  make_link_tree
  printf '%s\n' '${DOC_TITLE:docs/link.md|F}' > t.tpl
  out=$(bash "$SCRIPT" t.tpl 2>/dev/null)
  [ "$out" = "F" ]
}

@test "symlink as a parent directory is not read, fallback used" {
  make_link_tree
  printf '%s\n' '${DOC_TITLE:docs/dirlink/s.md|F}|${DOC_TITLE:docs/real/s.md|F}' > t.tpl
  out=$(bash "$SCRIPT" t.tpl 2>/dev/null)
  [ "$out" = "F|Target" ]
  run bash "$SCRIPT" --check-paths t.tpl
  [ "$status" -eq 1 ]
  [[ "$output" == *"docs/dirlink/s.md"* ]]
}

@test "path containing a space resolves" {
  make_link_tree
  mkdir -p "docs/a b"
  printf -- '---\ntitle: Spaced\n---\n' > "docs/a b/c.md"
  printf '%s\n' '${DOC_TITLE:docs/a b/c.md|F}' > t.tpl
  [ "$(bash "$SCRIPT" t.tpl)" = "Spaced" ]
}

@test "unreadable file falls back with a warning instead of aborting" {
  [ "$(id -u)" -ne 0 ] || skip "root can read any file"
  make_link_tree
  printf -- '---\ntitle: Secret\n---\n' > docs/locked.md
  chmod 000 docs/locked.md
  printf '%s\n' '${DOC_TITLE:docs/locked.md|F}' > t.tpl
  run bash "$SCRIPT" t.tpl
  [ "$status" -eq 0 ]
  [[ "$output" == *"::warning::"* ]]
  [ "${lines[${#lines[@]}-1]}" = "F" ]
}

# Edge cases of the frontmatter block itself, one file each.
resolve_title() { # <file content (printf format)>
  make_link_tree
  printf -- "$1" > docs/e.md
  printf '%s\n' '${DOC_TITLE:docs/e.md|F}' > t.tpl
  bash "$SCRIPT" t.tpl 2>/dev/null
}

@test "CRLF line endings resolve" {
  [ "$(resolve_title '---\r\ntitle: Crlf\r\n---\r\n')" = "Crlf" ]
}

@test "unterminated block is not frontmatter, fallback used" {
  [ "$(resolve_title '---\ntitle: Open\n')" = "F" ]
}

@test "empty value falls back" {
  [ "$(resolve_title '---\ntitle:\n---\n')" = "F" ]
  [ "$(resolve_title '---\ntitle: ""\n---\n')" = "F" ]
}

@test "duplicate keys: the first one wins, even when it is empty" {
  [ "$(resolve_title '---\ntitle: A\ntitle: B\n---\n')" = "A" ]
  [ "$(resolve_title '---\ntitle:\ntitle: B\n---\n')" = "F" ]
}

@test "block scalar indicators fall back instead of printing the indicator" {
  for ind in '>' '>-' '|' '|-' '>+' '|+'; do
    [ "$(resolve_title "---\ntitle: ${ind}\n  folded text\n---\n")" = "F" ]
  done
}

@test "missing template argument or file is an error" {
  run bash "$SCRIPT"
  [ "$status" -ne 0 ]
  run bash "$SCRIPT" docs/does-not-exist.tpl
  [ "$status" -ne 0 ]
}
