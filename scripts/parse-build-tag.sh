#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <build_tag> [output_file]" >&2
  echo "Example: $0 build/api34-35-j17-23-ndk26/v5" >&2
}

tag="${1:-}"
output_file="${2:-${GITHUB_OUTPUT:-}}"

if [[ -z "${tag}" ]]; then
  usage
  exit 1
fi

if [[ "${tag}" =~ ^build/([a-z0-9][a-z0-9-]*)/(v[0-9]+)$ ]]; then
  variant_id="${BASH_REMATCH[1]}"
  release="${BASH_REMATCH[2]}"
else
  echo "Invalid build tag: ${tag}" >&2
  echo "Expected format: build/<variant_id>/vN" >&2
  exit 1
fi

if [[ -n "${output_file}" ]]; then
  {
    echo "build_tag=${tag}"
    echo "variant_id=${variant_id}"
    echo "release=${release}"
  } >>"${output_file}"
else
  echo "build_tag=${tag}"
  echo "variant_id=${variant_id}"
  echo "release=${release}"
fi
