#!/usr/bin/env bash
set -euo pipefail

mode="${1:-built-in}"
if [[ "${mode}" != "built-in" ]]; then
  echo "Only 'built-in' mode is supported" >&2
  exit 1
fi

mkdir -p /opt/android-sdk-linux/bin/
cp /opt/tools/android-env.sh /opt/android-sdk-linux/bin/
source /opt/android-sdk-linux/bin/android-env.sh

cd "${ANDROID_HOME}"
echo "Set ANDROID_HOME to ${ANDROID_HOME}"

if [[ -f commandlinetools-linux.zip ]]; then
  echo "SDK Tools already bootstrapped. Skipping initial setup"
else
  echo "Bootstrapping SDK-Tools"
  wget -q https://dl.google.com/android/repository/commandlinetools-linux-6609375_latest.zip -O commandlinetools-linux.zip
  unzip commandlinetools-linux.zip
  mkdir -p cmdline-tools
  mv tools cmdline-tools/
  rm commandlinetools-linux.zip
fi

echo "Ensuring repositories.cfg exists"
mkdir -p ~/.android/
touch ~/.android/repositories.cfg

echo "Copying licenses"
cp -rv /opt/licenses "${ANDROID_HOME}/licenses"

echo "Copying tools"
mkdir -p "${ANDROID_HOME}/bin"
cp -v /opt/tools/*.sh "${ANDROID_HOME}/bin"

echo "Updating SDK metadata"
update_sdk

echo "Accepting SDK licenses"
android-accept-licenses.sh "sdkmanager --licenses --verbose"
