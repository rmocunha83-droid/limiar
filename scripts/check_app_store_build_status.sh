#!/usr/bin/env bash
set -euo pipefail

APP_APPLE_ID="${APP_APPLE_ID:-6783115468}"
APP_VERSION="${APP_VERSION:-1.0}"
BUILD_NUMBER="${BUILD_NUMBER:-23}"
PLATFORM="${PLATFORM:-ios}"

if [[ -z "${ASC_API_KEY_ID:-}" || -z "${ASC_ISSUER_ID:-}" ]]; then
  cat >&2 <<'EOF'
Missing App Store Connect credentials.

Set these environment variables before running:
  ASC_API_KEY_ID     App Store Connect API key ID
  ASC_ISSUER_ID      App Store Connect issuer ID

Optional:
  ASC_P8_FILE        Path to the .p8 private key file

Example:
  ASC_API_KEY_ID=ABC123DEF4 \
  ASC_ISSUER_ID=00000000-0000-0000-0000-000000000000 \
  ASC_P8_FILE=/secure/path/AuthKey_ABC123DEF4.p8 \
  scripts/check_app_store_build_status.sh
EOF
  exit 2
fi

args=(
  --build-status
  --apple-id "$APP_APPLE_ID"
  --bundle-short-version-string "$APP_VERSION"
  --bundle-version "$BUILD_NUMBER"
  --platform "$PLATFORM"
  --api-key "$ASC_API_KEY_ID"
  --api-issuer "$ASC_ISSUER_ID"
)

if [[ -n "${ASC_P8_FILE:-}" ]]; then
  if [[ ! -f "$ASC_P8_FILE" ]]; then
    echo "ASC_P8_FILE does not exist: $ASC_P8_FILE" >&2
    exit 2
  fi
  args+=(--p8-file-path "$ASC_P8_FILE")
fi

xcrun altool "${args[@]}"
