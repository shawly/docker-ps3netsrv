#!/usr/bin/env bash
#
# Print the build matrix as {"releases":[...],"bases":[...]}.
#
# Releases are the newest RELEASE_COUNT upstream ps3netsrv releases plus an
# edge entry that tracks upstream master.
#
# Bases are read out of the Dockerfiles, so a Dependabot bump of a FROM line
# flows into the image tags without anything else being touched.
#
# Needs gh (authenticated) and jq. Run from the repository root.
#
set -euo pipefail

RELEASE_COUNT="${RELEASE_COUNT:-3}"
UPSTREAM_REPO="${UPSTREAM_REPO:-aldostools/ps3netsrv}"

versions=$(gh api "repos/${UPSTREAM_REPO}/releases?per_page=20" \
  --jq '[.[] | select(.draft == false and .prerelease == false) | .tag_name]')

releases=$(jq -cn \
  --argjson versions "$versions" \
  --argjson count "${RELEASE_COUNT}" '
    [ $versions[0:$count] | to_entries[] | {
        version: .value,
        ref: .value,
        edge: false,
        latest: (.key == 0)
      } ]
    + [ { version: "edge", ref: "master", edge: true, latest: false } ]
  ')

alpine_version=$(grep -oP '^FROM alpine:\K[0-9]+\.[0-9]+' alpine.Dockerfile | head -1)
debian_suite=$(grep -oP '^FROM debian:\K[a-z]+-slim' slim.Dockerfile | head -1)
: "${alpine_version:?could not read alpine version from alpine.Dockerfile}"
: "${debian_suite:?could not read debian suite from slim.Dockerfile}"

bases=$(jq -cn \
  --arg alpine_version "$alpine_version" \
  --arg debian_suite "$debian_suite" '
    [ { name: "alpine",
        dockerfile: "alpine.Dockerfile",
        tag: ("alpine" + $alpine_version),
        alias: "alpine",
        default: true },
      { name: "slim",
        dockerfile: "slim.Dockerfile",
        tag: $debian_suite,
        alias: "slim",
        default: false } ]
  ')

jq -cn --argjson releases "$releases" --argjson bases "$bases" \
  '{releases: $releases, bases: $bases}'
