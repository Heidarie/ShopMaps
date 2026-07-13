#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

forbidden_files=(
  "android/app/google-services.json"
  "android/key.properties"
  "firebase.json"
  "ios/Flutter/Secrets.xcconfig"
  "ios/Runner/GoogleService-Info.plist"
  "lib/firebase_options.dart"
  "config/supabase.dev.json"
  "config/supabase.prod.json"
  "supabase/functions/.env"
  "supabase/functions/.env.dev"
  "supabase/functions/.env.prod"
)

failed=0
for file in "${forbidden_files[@]}"; do
  if git ls-files --error-unmatch "$file" >/dev/null 2>&1; then
    echo "Secret check failed: tracked configuration file: $file" >&2
    failed=1
  fi
done

if git ls-files | grep -E \
  '(^|/)(\.env(\..+)?|.*\.p8|.*\.p12|.*\.pem|.*firebase-adminsdk.*\.json|.*service-account.*\.json)$' |
  grep -v -E '(^|/)\.env\.example$'; then
  echo "Secret check failed: tracked sensitive file type." >&2
  failed=1
fi

patterns=(
  'AIza[0-9A-Za-z_-]{20,}'
  'sb_secret_[0-9A-Za-z_-]{20,}'
  'sb_publishable_[0-9A-Za-z_-]{20,}'
  'eyJ[0-9A-Za-z_-]{20,}\.[0-9A-Za-z_-]{20,}\.[0-9A-Za-z_-]{20,}'
  '[0-9]{8,}-[0-9A-Za-z_-]{10,}\.apps\.googleusercontent\.com'
  '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----$'
)

for pattern in "${patterns[@]}"; do
  if git grep --untracked --exclude-standard -I -l -E -e "$pattern" -- . \
    ':(exclude)scripts/check-secrets.sh' \
    ':(exclude)ios/Flutter/Secrets.xcconfig.example'; then
    echo "Secret check failed: tracked content matched a protected key pattern." >&2
    failed=1
  fi
done

if [[ "$failed" != "0" ]]; then
  exit 1
fi

echo "Secret check passed."
