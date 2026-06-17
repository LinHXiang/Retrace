#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ARCHIVE_DIR="$ROOT_DIR/build/release"
DERIVED_DATA_DIR="${DERIVED_DATA_DIR:-$ROOT_DIR/build/DerivedData/Release}"
PRODUCT_APP="$DERIVED_DATA_DIR/Build/Products/Release/Retrace.app"
SIGNED_APP="$ARCHIVE_DIR/Retrace.app"
NOTARY_ZIP="$ARCHIVE_DIR/Retrace-notary.zip"
VERSION="${1:-}"
TEAM_ID="${TEAM_ID:-BN7K93LTRY}"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-Developer ID Application: weijing wu (BN7K93LTRY)}"
NOTARY_PROFILE="${NOTARY_PROFILE:-retrace-notary}"

cd "$ROOT_DIR"

if [[ -z "$VERSION" ]]; then
  VERSION="$(xcodebuild -project Retrace.xcodeproj -scheme Retrace -showBuildSettings 2>/dev/null \
    | awk -F '= ' '/MARKETING_VERSION/ { print $2; exit }')"
fi

if [[ -z "$VERSION" ]]; then
  echo "Could not determine version. Pass one explicitly, e.g. scripts/package_release.sh 1.0.0" >&2
  exit 1
fi

FINAL_ZIP="$ARCHIVE_DIR/Retrace-$VERSION.zip"

rm -rf "$ARCHIVE_DIR"
mkdir -p "$ARCHIVE_DIR"

xcodebuild build \
  -project Retrace.xcodeproj \
  -scheme Retrace \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA_DIR" \
  -skipPackagePluginValidation \
  -skipPackageUpdates \
  -onlyUsePackageVersionsFromResolvedFile \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" \
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO

ditto "$PRODUCT_APP" "$SIGNED_APP"

codesign --verify --deep --strict --verbose=2 "$SIGNED_APP"
if codesign -d --entitlements :- "$SIGNED_APP" 2>/dev/null | grep -q "com.apple.security.get-task-allow"; then
  echo "Release build contains com.apple.security.get-task-allow; refusing to notarize." >&2
  exit 1
fi

ditto -c -k --keepParent "$SIGNED_APP" "$NOTARY_ZIP"

xcrun notarytool submit "$NOTARY_ZIP" \
  --keychain-profile "$NOTARY_PROFILE" \
  --wait

xcrun stapler staple "$SIGNED_APP"
xcrun stapler validate "$SIGNED_APP"

rm -f "$FINAL_ZIP"
ditto -c -k --keepParent "$SIGNED_APP" "$FINAL_ZIP"

echo
echo "Release archive:"
echo "$FINAL_ZIP"
echo
echo "SHA-256:"
shasum -a 256 "$FINAL_ZIP"
echo
echo "Gatekeeper assessment:"
spctl --assess --type execute --verbose "$SIGNED_APP"
