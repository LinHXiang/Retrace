#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA_DIR="${DERIVED_DATA_DIR:-$ROOT_DIR/build/DerivedData/Install}"
PRODUCT_APP="$DERIVED_DATA_DIR/Build/Products/Release/Retrace.app"
DESTINATION_APP="/Applications/Retrace.app"

cd "$ROOT_DIR"

xcodebuild build \
  -project Retrace.xcodeproj \
  -scheme Retrace \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA_DIR" \
  -skipPackagePluginValidation \
  -skipPackageUpdates \
  -onlyUsePackageVersionsFromResolvedFile

osascript -e 'tell application "Retrace" to quit' >/dev/null 2>&1 || true
sleep 1
pkill -x Retrace >/dev/null 2>&1 || true

rm -rf "$DESTINATION_APP"
ditto "$PRODUCT_APP" "$DESTINATION_APP"

/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister \
  -f "$DESTINATION_APP"

open -a "$DESTINATION_APP"
