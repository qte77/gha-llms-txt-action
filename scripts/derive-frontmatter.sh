#!/usr/bin/env bash
# Resolve ${DOC_TITLE:path|Fallback} and ${DOC_PURPOSE:path|Fallback} tokens in an
# llms.txt template from the leading YAML frontmatter block of the named file.
# Runs before envsubst; all other text (including ${BLOB} etc.) passes through untouched.
#
# Usage:
#   derive-frontmatter.sh <template>               resolved template on stdout
#   derive-frontmatter.sh --list-paths <template>  one DOC_* token path per line
#
# File content is untrusted: it is only read with awk and handled as data, never
# evaluated. Needs bash, awk; no yq.
set -euo pipefail

NL=$'\n'
# group 1 = TITLE|PURPOSE, group 2 = path, group 4 = fallback (optional)
TOKEN_RE="\\$\\{DOC_(TITLE|PURPOSE):([^}|${NL}]+)(\\|([^}${NL}]*))?\\}"

# Print the value of <key> from the leading frontmatter block of <file>, or nothing.
# Only line 1 == "---" opens a block; the next "---" or "..." closes it. A block that
# never closes is not frontmatter. Surrounding matching quotes are stripped; the rest
# of the value (including colons) is kept as is.
extract() {
  awk -v key="$2" '
    { sub(/\r$/, "") }
    NR == 1 { if ($0 != "---") exit; next }
    $0 == "---" || $0 == "..." { closed = 1; exit }
    !set && index($0, key ":") == 1 {
      v = substr($0, length(key) + 2)
      sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
      n = length(v)
      if (n >= 2) {
        f = substr(v, 1, 1); l = substr(v, n, 1)
        if ((f == "\"" || f == "\047") && f == l) v = substr(v, 2, n - 2)
      }
      val = v; set = 1
    }
    END { if (closed && set) print val }
  ' < "$1"
}

# A token path must be a plain relative path to a regular, non-symlink file.
safe_path() {
  case "$1" in
    /* | .. | ../* | */.. | */../*) return 1 ;;
  esac
  [ -f "$1" ] && [ ! -L "$1" ]
}

list_only=0
if [ "${1:-}" = "--list-paths" ]; then
  list_only=1
  shift
fi
template=${1:-}
if [ -z "$template" ] || [ ! -f "$template" ]; then
  echo "usage: derive-frontmatter.sh [--list-paths] <template>" >&2
  exit 2
fi

# Read the whole template so output is byte-identical when no token matches
# (the sentinel keeps trailing newlines).
content=$(cat -- "$template" && printf x)
content=${content%x}

out=""
rest=$content
while [[ $rest =~ $TOKEN_RE ]]; do
  match=${BASH_REMATCH[0]}
  kind=${BASH_REMATCH[1]}
  path=${BASH_REMATCH[2]}
  fallback=${BASH_REMATCH[4]}
  pre=${rest%%"$match"*}
  rest=${rest#*"$match"}

  if [ "$list_only" -eq 1 ]; then
    printf '%s\n' "$path"
    continue
  fi

  case "$kind" in
    TITLE) key=title ;;
    *) key=purpose ;;
  esac
  value=""
  if safe_path "$path"; then
    value=$(extract "$path" "$key")
  else
    echo "::warning::DOC_${kind}: not a readable repo-relative file: ${path}" >&2
  fi
  [ -n "$value" ] || value=$fallback
  out+="${pre}${value}"
done

if [ "$list_only" -eq 0 ]; then
  printf '%s' "${out}${rest}"
fi
