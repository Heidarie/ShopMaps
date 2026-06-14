#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

CONFIG_PATH="${1:-config/supabase.prod.json}"

dart run tool/validate_production_config.dart "$CONFIG_PATH"

if [[ ! -f android/key.properties ]]; then
  echo "Production release check failed: create android/key.properties." >&2
  exit 1
fi

for key in storePassword keyPassword keyAlias storeFile; do
  if ! rg -q "^${key}=.+" android/key.properties; then
    echo "Production release check failed: android/key.properties is missing ${key}." >&2
    exit 1
  fi
done

if rg -q 'CHANGE_ME|REPLACE_ME' android/key.properties; then
  echo "Production release check failed: complete android/key.properties." >&2
  exit 1
fi

STORE_FILE="$(sed -n 's/^storeFile=//p' android/key.properties | tail -1)"
if [[ "$STORE_FILE" = /* ]]; then
  KEYSTORE_PATH="$STORE_FILE"
else
  KEYSTORE_PATH="android/app/$STORE_FILE"
fi
if [[ -z "$STORE_FILE" || ! -f "$KEYSTORE_PATH" ]]; then
  echo "Production release check failed: Android upload keystore was not found." >&2
  exit 1
fi

if rg -q '\[DO UZUPEŁNIENIA|\[DO WERYFIKACJI' \
  docs/index.html docs/regulamin-template-pl.md; then
  echo "Production release check failed: complete the privacy policy and terms." >&2
  exit 1
fi

if rg -q 'signingConfig = signingConfigs\.getByName\("debug"\)' android/app/build.gradle.kts; then
  echo "Production release check failed: Android release still uses debug signing." >&2
  exit 1
fi

if ! rg -q 'APS_ENVIRONMENT = production;' ios/Runner.xcodeproj/project.pbxproj; then
  echo "Production release check failed: iOS Release APNs environment is not production." >&2
  exit 1
fi

if [[ "${SKIP_QUALITY_CHECKS:-0}" != "1" ]]; then
  flutter analyze
  flutter test
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Warning: the working tree is dirty. Commit the intended release before publishing." >&2
fi

echo "Production release checks passed."
