#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

CONFIG_PATH="${PRODUCTION_CONFIG:-config/supabase.prod.json}"
EXPORT_OPTIONS_PATH="${IOS_EXPORT_OPTIONS_PLIST:-ios/ExportOptions.plist}"
scripts/use-firebase-environment.sh prod
scripts/check-production-release.sh "$CONFIG_PATH" ios

flutter build ipa --release \
  --dart-define-from-file="$CONFIG_PATH" \
  --export-options-plist="$EXPORT_OPTIONS_PATH" \
  "$@"
