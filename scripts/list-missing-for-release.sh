#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  list-missing-for-release.sh --release <vN> --docker-user <user> [--variants-file <path>] [--output <path>]
USAGE
}

release=""
docker_user="${DOCKER_USER:-}"
variants_file="${VARIANTS_FILE:-variants.json}"
output_file="${GITHUB_OUTPUT:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --release)
      release="$2"
      shift 2
      ;;
    --docker-user)
      docker_user="$2"
      shift 2
      ;;
    --variants-file)
      variants_file="$2"
      shift 2
      ;;
    --output)
      output_file="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "${release}" || -z "${docker_user}" ]]; then
  usage
  exit 1
fi

if [[ ! "${release}" =~ ^v[0-9]+$ ]]; then
  echo "Invalid release format: ${release} (expected vN)" >&2
  exit 1
fi

if [[ ! -f "${variants_file}" ]]; then
  echo "Variants file not found: ${variants_file}" >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "docker command is required" >&2
  exit 1
fi

image_repo="$(jq -r '.image_repo' "${variants_file}")"

missing_ids=()
while IFS= read -r variant_id; do
  candidate_tag="${docker_user}/${image_repo}:${variant_id}-${release}"
  if docker buildx imagetools inspect "${candidate_tag}" >/dev/null 2>&1; then
    echo "existing: ${candidate_tag}" >&2
  else
    echo "missing: ${candidate_tag}" >&2
    missing_ids+=("${variant_id}")
  fi
done < <(jq -r '.variants | keys[]' "${variants_file}")

if [[ ${#missing_ids[@]} -eq 0 ]]; then
  matrix='{"include":[]}'
else
  matrix="$(printf '%s\n' "${missing_ids[@]}" | jq -R . | jq -cs '{include: map({variant_id: .})}')"
fi

missing_count="${#missing_ids[@]}"
missing_csv="$(IFS=','; echo "${missing_ids[*]:-}")"

if [[ -n "${output_file}" ]]; then
  {
    echo "missing_count=${missing_count}"
    echo "missing_csv=${missing_csv}"
    echo "matrix=${matrix}"
  } >>"${output_file}"
else
  echo "missing_count=${missing_count}"
  echo "missing_csv=${missing_csv}"
  echo "matrix=${matrix}"
fi
