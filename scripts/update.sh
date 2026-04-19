#!/usr/bin/env bash
# update.sh - Update an existing dade.micro.blog post or page via Micropub.
#
# Reads YAML frontmatter from a markdown file under posts/ or pages/, requires
# `url:` (set by post.sh / publish-pages.sh on initial publish), and POSTs a
# JSON Micropub update action that replaces content (and, if present in
# frontmatter, name and category) for that URL.
#
# Exit codes:
#   2  usage / missing or unreadable file / malformed frontmatter
#   3  missing or empty token
#   4  not yet published (no url: in frontmatter)
#   5  HTTP error from Micropub endpoint
#   6  target is a static page (not Micropub-addressable)

set -euo pipefail

MICROPUB_URL="https://micro.blog/micropub"

usage() {
  echo "usage: $(basename "$0") <markdown-file>" >&2
  exit 2
}

[[ $# -eq 1 ]] || usage
SRC="$1"
if [[ ! -f "$SRC" ]]; then
  echo "error: file not found: $SRC" >&2
  exit 2
fi

TOKEN_FILE="$HOME/.config/microblog/token"
if [[ ! -f "$TOKEN_FILE" ]]; then
  echo "error: token file not found: $TOKEN_FILE" >&2
  exit 3
fi
TOKEN="$(tr -d '[:space:]' < "$TOKEN_FILE")"
if [[ -z "$TOKEN" ]]; then
  echo "error: token file is empty: $TOKEN_FILE" >&2
  exit 3
fi

_SRC_NORM="${SRC#./}"
if [[ "$_SRC_NORM" == pages/* ]]; then
  echo "error: pages are not updatable via Micropub; edit in the Micro.blog dashboard (Posts → Pages → <page>) then re-run publish-pages.sh only if you want to overwrite the local file" >&2
  exit 6
fi

first_line="$(head -n 1 "$SRC")"
if [[ "$first_line" != "---" ]]; then
  echo "error: file does not start with YAML frontmatter (---)" >&2
  exit 2
fi

FM_END=0
_ln=0
while IFS= read -r _line || [[ -n "$_line" ]]; do
  _ln=$((_ln + 1))
  if [[ $_ln -gt 1 && "$_line" =~ ^---[[:space:]]*$ ]]; then
    FM_END=$_ln
    break
  fi
done < "$SRC"
if [[ $FM_END -eq 0 ]]; then
  echo "error: no closing --- for frontmatter" >&2
  exit 2
fi

FM=""
_ln=0
while IFS= read -r _line || [[ -n "$_line" ]]; do
  _ln=$((_ln + 1))
  if [[ $_ln -le 1 ]]; then
    continue
  fi
  if [[ $_ln -ge $FM_END ]]; then
    break
  fi
  FM+="${_line}"$'\n'
done < "$SRC"

EXISTING_URL=$(printf '%s' "$FM" \
  | sed -nE 's/^url:[[:space:]]*"?([^"#]+[^"[:space:]#])"?[[:space:]]*$/\1/p' \
  | head -n 1)
if [[ -z "$EXISTING_URL" ]]; then
  echo "not yet published: no url: in frontmatter; use post.sh or publish-pages.sh" >&2
  exit 4
fi

TITLE=""
while IFS= read -r _line; do
  if [[ "$_line" =~ ^title:[[:space:]]*(.*)$ ]]; then
    TITLE="${BASH_REMATCH[1]}"
    TITLE="${TITLE%$'\r'}"
    while [[ -n "$TITLE" && "${TITLE: -1}" =~ [[:space:]] ]]; do
      TITLE="${TITLE%?}"
    done
    if [[ "$TITLE" =~ ^\"(.*)\"$ ]]; then
      TITLE="${BASH_REMATCH[1]}"
    fi
    break
  fi
done <<<"$FM"

CATS_LINE=$(printf '%s' "$FM" \
  | sed -nE 's/^categories:[[:space:]]*\[(.*)\][[:space:]]*$/\1/p' \
  | head -n 1)

CATEGORIES=()
if [[ -n "$CATS_LINE" ]]; then
  while IFS= read -r cat; do
    [[ -n "$cat" ]] && CATEGORIES+=("$cat")
  done < <(printf '%s\n' "$CATS_LINE" \
    | grep -oE '"[^"]*"' \
    | sed -E 's/^"//; s/"$//' \
    || true)
fi

BODY=$(sed -n "$((FM_END + 1)),\$p" "$SRC")

# Pure-bash JSON string escape: backslash, double-quote, and control chars
# \n \r \t. Other control chars are passed through; the inputs we deal with
# (markdown body, title, category names) don't contain raw NULs or other
# unprintables in practice.
json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\n'/\\n}"
  printf '%s' "$s"
}

URL_ESC=$(json_escape "$EXISTING_URL")
BODY_ESC=$(json_escape "$BODY")

REPLACE=$(printf '"content": ["%s"]' "$BODY_ESC")

if [[ -n "$TITLE" ]]; then
  TITLE_ESC=$(json_escape "$TITLE")
  REPLACE+=$(printf ', "name": ["%s"]' "$TITLE_ESC")
fi

if [[ ${#CATEGORIES[@]} -gt 0 ]]; then
  CAT_JSON=""
  for c in "${CATEGORIES[@]}"; do
    c_esc=$(json_escape "$c")
    if [[ -z "$CAT_JSON" ]]; then
      CAT_JSON=$(printf '"%s"' "$c_esc")
    else
      CAT_JSON+=$(printf ', "%s"' "$c_esc")
    fi
  done
  REPLACE+=$(printf ', "category": [%s]' "$CAT_JSON")
fi

PAYLOAD=$(printf '{"action": "update", "url": "%s", "replace": {%s}}' "$URL_ESC" "$REPLACE")

RESP_BODY=$(mktemp)
trap 'rm -f "$RESP_BODY"' EXIT

STATUS=$(curl -sS -X POST "$MICROPUB_URL" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -o "$RESP_BODY" \
  -w "%{http_code}" \
  --data-binary "$PAYLOAD")

case "$STATUS" in
  200|201|202|204)
    echo "updated: $EXISTING_URL"
    exit 0
    ;;
  *)
    echo "error: HTTP $STATUS from $MICROPUB_URL" >&2
    cat "$RESP_BODY" >&2
    echo >&2
    exit 5
    ;;
esac
