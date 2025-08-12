#!/bin/bash
set -euo pipefail

# Function to configure git proxy based on env vars
configure_git_proxy() {
  if [[ "${GIT_PROXY_ENABLED:-false}" == "true" ]]; then
    # Check required vars
    if [[ -z "${GIT_PROXY_URL:-}" || -z "${GIT_PROXY_BASEURL:-}" ]]; then
      echo "Error: GIT_PROXY_URL and GIT_PROXY_BASEURL must be set when proxy is enabled"
      exit 1
    fi

    echo "Enabling git proxy for $GIT_PROXY_BASEURL via $GIT_PROXY_URL"
    git config --system "http.${GIT_PROXY_BASEURL}.proxy" "$GIT_PROXY_URL"
    git config --system "https.${GIT_PROXY_BASEURL}.proxy" "$GIT_PROXY_URL"
  else
    if [[ -n "${GIT_PROXY_BASEURL:-}" ]]; then
      echo "Disabling git proxy for $GIT_PROXY_BASEURL"
      git config --system --remove-section "http.${GIT_PROXY_BASEURL}.proxy" 2>/dev/null || true
      git config --system --remove-section "https.${GIT_PROXY_BASEURL}.proxy" 2>/dev/null || true
    else
      echo "GIT_PROXY_BASEURL not set, skipping proxy removal"
    fi
  fi
}

# Run git proxy config
configure_git_proxy