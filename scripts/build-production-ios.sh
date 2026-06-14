#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

CONFIG_PATH="${PRODUCTION_CONFIG:-config/supabase.prod.json}"
scripts/use-firebase-environment.sh prod
scripts/check-production-release.sh "$CONFIG_PATH"

flutter build ipa --release \
  --dart-define-from-file="$CONFIG_PATH" \
  "$@"
