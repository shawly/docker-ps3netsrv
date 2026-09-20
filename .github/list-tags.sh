#!/usr/bin/env bash
#
# Emit the docker tags for one (release, base) pair, one per line, sorted.
#
# Usage: list-tags.sh <release-json> <base-json> [release-state-json]
#
#   release-json        {"version":"20260913","latest":true,...}
#   base-json           {"tag":"alpine3.23","alias":"alpine","default":true,...}
#   release-state-json  contents of .github/release.json, i.e.
#                       {"version":"1.12.0","ps3netsrv_version":"20260913"}
#
# Follows the convention of the official Docker library images: the base image
# version is part of the tag (20260913-alpine3.23), the base family is an alias
# for the newest of them (20260913-alpine), and the default base also owns the
# bare tags (20260913, latest).
#
# This repository's own vX.Y.Z tags are stamped onto whichever ps3netsrv
# version the current release actually shipped, which is what release.json
# records. They are deliberately not tied to "newest upstream release": once
# upstream publishes something newer, latest moves and v1.12.0 does not.
#
set -euo pipefail

release="${1:?release json required}"
base="${2:?base json required}"
release_state="${3:-}"

version="$(jq -r '.version' <<< "$release")"
is_latest="$(jq -r '.latest' <<< "$release")"

base_tag="$(jq -r '.tag' <<< "$base")"
base_alias="$(jq -r '.alias' <<< "$base")"
is_default="$(jq -r '.default' <<< "$base")"

tags=()

# Always: the version on this exact base, plus the base family alias
tags+=("${version}-${base_tag}" "${version}-${base_alias}")
if [ "${is_default}" = "true" ]; then
  tags+=("${version}")
fi

# Newest upstream release owns the bare base tags
if [ "${is_latest}" = "true" ]; then
  tags+=("${base_tag}" "${base_alias}")
  if [ "${is_default}" = "true" ]; then
    tags+=("latest")
  fi
fi

# This repository's release tags land on the ps3netsrv version they shipped
if [ -n "${release_state}" ]; then
  release_version="$(jq -r '.version' <<< "$release_state")"
  release_ps3netsrv="$(jq -r '.ps3netsrv_version' <<< "$release_state")"

  if [ "${version}" = "${release_ps3netsrv}" ]; then
    minor="${release_version%.*}"
    major="${minor%.*}"
    for v in "v${release_version}" "v${minor}" "v${major}"; do
      tags+=("${v}-${base_tag}" "${v}-${base_alias}")
      if [ "${is_default}" = "true" ]; then
        tags+=("${v}")
      fi
    done
  fi
fi

printf '%s\n' "${tags[@]}" | sort -u
