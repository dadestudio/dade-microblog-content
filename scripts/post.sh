#!/usr/bin/env bash
# post.sh - Post a markdown file to dade.micro.blog via Micropub.
#
# Reads YAML frontmatter (title optional, categories as ["A","B"] array),
# POSTs body + metadata to the Micropub endpoint with a bearer token from
# ~/.config/microblog/token, and writes the returned post URL back into the
# source file's frontmatter as `url:` so future runs refuse to repost it.
#
# Exit codes:
#   2  usage / missing or unreadable file / malformed frontmatter
#   3  missing or empty token
#   4  refusing to repost (frontmatter url: is already set)
#   5  HTTP error from Micropub endpoint

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
if [[ -n "$EXISTING_URL" ]]; then
  echo "already published: $EXISTING_URL; use update.sh" >&2
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

CURL_DATA=(--data-urlencode "h=entry" --data-urlencode "content=$BODY")

if [[ -n "$TITLE" ]]; then
  CURL_DATA+=(--data-urlencode "name=$TITLE")
fi

# Bash 3.2-safe expansion for possibly-empty array.
for c in ${CATEGORIES[@]+"${CATEGORIES[@]}"}; do
  CURL_DATA+=(--data-urlencode "category[]=$c")
done

HDR=$(mktemp)
RESP_BODY=$(mktemp)
trap 'rm -f "$HDR" "$RESP_BODY"' EXIT

STATUS=$(curl -sS -X POST "$MICROPUB_URL" \
  -H "Authorization: Bearer $TOKEN" \
  -D "$HDR" \
  -o "$RESP_BODY" \
  -w "%{http_code}" \
  "${CURL_DATA[@]}")

if [[ "$STATUS" != "201" && "$STATUS" != "202" ]]; then
  echo "error: HTTP $STATUS from $MICROPUB_URL" >&2
  cat "$RESP_BODY" >&2
  echo >&2
  exit 5
fi

LOCATION=$(grep -i '^Location:' "$HDR" \
  | tail -n 1 \
  | sed -E 's/^[Ll]ocation:[[:space:]]*//' \
  | tr -d '\r\n' \
  || true)

if [[ -z "$LOCATION" ]]; then
  echo "error: HTTP $STATUS but no Location header in response" >&2
  cat "$HDR" >&2
  exit 5
fi

echo "$LOCATION"

TMP=$(mktemp)
_ln=0
_inserted=0
while IFS= read -r _line || [[ -n "$_line" ]]; do
  _ln=$((_ln + 1))
  if [[ $_inserted -eq 0 && $_ln -eq $FM_END ]]; then
    printf '%s\n' "url: $LOCATION"
    _inserted=1
  fi
  printf '%s\n' "$_line"
done < "$SRC" > "$TMP"
mv "$TMP" "$SRC"
