#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [[ "$(uname -s)" != Darwin ]] || ! command -v xcodebuild >/dev/null 2>&1; then
  echo "This build needs Xcode on macOS. Use the included GitHub Actions workflow from Windows."
  exit 1
fi
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "Install XcodeGen first: brew install xcodegen"
  exit 1
fi

build_root="$repo_root/build-mph"
mkdir -p "$build_root" "$repo_root/dist"

xcrun swiftc Locus/Support/MovementSpeed.swift Locus/Support/PlaybackProgress.swift scripts/check_movement_speed.swift \
  -o "$build_root/check-movement-speed"
"$build_root/check-movement-speed"
xcrun swiftc Locus/Support/MovementSpeed.swift Locus/Support/NativeLocationPayload.swift \
  Locus/Support/TunnelAddressMatcher.swift scripts/check_native_speed.swift \
  -o "$build_root/check-native-speed"
"$build_root/check-native-speed"

xcodegen generate
if ! xcodebuild \
  -project Locus.xcodeproj \
  -scheme Locus \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$build_root/DerivedData" \
  ARCHS=arm64 \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY='' \
  DEVELOPMENT_TEAM='' \
  build > "$build_root/xcodebuild.log" 2>&1; then
  tail -n 120 "$build_root/xcodebuild.log"
  exit 1
fi

app_path="$build_root/DerivedData/Build/Products/Release-iphoneos/Locus.app"
test -f "$app_path/Locus"
package_root="$(mktemp -d "$build_root/ipa.XXXXXX")"
trap 'rm -rf "$package_root"' EXIT
mkdir -p "$package_root/Payload"
cp -R "$app_path" "$package_root/Payload/Locus.app"
cp LICENSE "$package_root/Payload/Locus.app/LocusLicense.txt"
ditto -c -k --sequesterRsrc --keepParent \
  "$package_root/Payload" "$repo_root/dist/Locus-MPH-unsigned.ipa"
echo "Created dist/Locus-MPH-unsigned.ipa. Sign it with your sideloading tool before installing."
