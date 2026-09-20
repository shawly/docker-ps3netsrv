#!/usr/bin/env bash
#
# Rewrite the supported tags block in README.md, in the layout the official
# Docker library images use: one entry per image, tab after the bullet, blank
# line between entries, tags sorted, each entry linking to its Dockerfile.
#
# Usage: render-readme-tags.sh <repo-url> [matrix-json]
#
#   repo-url     e.g. https://github.com/shawly/docker-ps3netsrv
#   matrix-json  output of release-matrix.sh; computed here when not given
#
# Reads .github/release.json so this repository's own release tags are drawn
# onto the ps3netsrv version they actually shipped. Run from the repo root.
#
set -euo pipefail

repo_url="${1:?repo url required}"
matrix="${2:-$(.github/release-matrix.sh)}"

releases=$(jq -c '.releases' <<< "$matrix")
bases=$(jq -c '.bases' <<< "$matrix")
release_state=$(cat .github/release.json)

entries=()
while read -r release; do
  while read -r base; do
    dockerfile=$(jq -r '.dockerfile' <<< "$base")
    tags=$(.github/list-tags.sh "$release" "$base" "$release_state" \
      | sed 's/^/`/; s/$/`/' | paste -sd, - | sed 's/,/, /g')
    entries+=("$(printf -- '-\t[%s](%s)' "${tags}" "${repo_url}/blob/main/${dockerfile}")")
  done < <(jq -c '.[]' <<< "$bases")
done < <(jq -c '.[]' <<< "$releases")

block=$(
  echo "<!-- tags start -->"
  printf '%s\n\n' "${entries[@]}" | head -c -1
  echo "<!-- tags end -->"
)

BLOCK="$block" python3 - <<'PY'
import os, re, pathlib

readme = pathlib.Path("README.md")
block = os.environ["BLOCK"]
text = readme.read_text()
new, count = re.subn(
    r"<!-- tags start -->.*?<!-- tags end -->",
    lambda _: block,
    text,
    flags=re.S,
)
if count != 1:
    raise SystemExit(f"expected one tags block in README.md, found {count}")
if new == text:
    print("Supported tags already up to date.")
else:
    readme.write_text(new)
    print("Supported tags updated.")
PY

echo "$block"
