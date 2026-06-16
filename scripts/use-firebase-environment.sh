#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENVIRONMENT="${1:-}"
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
  echo "Usage: scripts/use-firebase-environment.sh <dev|prod>" >&2
  exit 1
fi

SOURCE="config/firebase/$ENVIRONMENT"
for file in google-services.json GoogleService-Info.plist Secrets.xcconfig firebase.json; do
  if [[ ! -f "$SOURCE/$file" ]]; then
    echo "Firebase snapshot is incomplete: missing $SOURCE/$file" >&2
    exit 1
  fi
done

cp "$SOURCE/google-services.json" android/app/google-services.json
cp "$SOURCE/GoogleService-Info.plist" ios/Runner/GoogleService-Info.plist
cp "$SOURCE/Secrets.xcconfig" ios/Flutter/Secrets.xcconfig
cp "$SOURCE/firebase.json" firebase.json

echo "Activated $ENVIRONMENT Firebase configuration."
