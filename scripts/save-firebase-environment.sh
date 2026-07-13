#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENVIRONMENT="${1:-}"
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
  echo "Usage: scripts/save-firebase-environment.sh <dev|prod>" >&2
  exit 1
fi

DESTINATION="config/firebase/$ENVIRONMENT"
mkdir -p "$DESTINATION"

cp android/app/google-services.json "$DESTINATION/google-services.json"
cp ios/Runner/GoogleService-Info.plist "$DESTINATION/GoogleService-Info.plist"
cp ios/Flutter/Secrets.xcconfig "$DESTINATION/Secrets.xcconfig"
cp firebase.json "$DESTINATION/firebase.json"

echo "Saved current Firebase configuration as $ENVIRONMENT."
