#!/usr/bin/env bash
set -euo pipefail

function checkbin() {
    type -P su-exec >/dev/null 2>&1
}

chown android:android /opt/android-sdk-linux

if checkbin; then
    exec su-exec android:android /opt/tools/android-sdk-update.sh "$@"
else
    exec su android -s /bin/bash -c '/opt/tools/android-sdk-update.sh "$@"' -- "$@"
fi
