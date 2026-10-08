#!/usr/bin/env bash
set -euo pipefail

helper_repo="$1"
helper_dist="$2"
helper_root="$(cd "$helper_repo" && pwd)"
mkdir -p "$helper_dist"
helper_dist="$(cd "$helper_dist" && pwd)"
helper_inputs="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$helper_inputs/patch_wda.py" "$helper_root"

if ! xcodebuild build-for-testing \
  -project "$helper_root/WebDriverAgent.xcodeproj" \
  -scheme WebDriverAgentRunner \
  -configuration Debug \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$helper_root/build-native-speed" \
  ARCHS=arm64 \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY='' \
  DEVELOPMENT_TEAM='' \
  GCC_TREAT_WARNINGS_AS_ERRORS=NO \
  > "$helper_dist/helper-xcodebuild.log" 2>&1; then
  tail -n 100 "$helper_dist/helper-xcodebuild.log"
  exit 1
fi

helper_app="$helper_root/build-native-speed/Build/Products/Debug-iphoneos/WebDriverAgentRunner-Runner.app"
test -f "$helper_app/WebDriverAgentRunner-Runner"
python3 - "$helper_app" <<'PY'
from pathlib import Path
import plistlib
import shutil
import sys

app = Path(sys.argv[1])
for path in (app / "Frameworks").glob("XC*"):
    if path.is_dir():
        shutil.rmtree(path)
    else:
        path.unlink()
for name in ["Testing.framework", "libXCTestSwiftSupport.dylib"]:
    path = app / "Frameworks" / name
    if path.is_dir():
        shutil.rmtree(path)
    elif path.exists():
        path.unlink()
info_path = app / "Info.plist"
info = plistlib.loads(info_path.read_bytes())
info["CFBundleIdentifier"] = "com.chrismack.locus.nativespeed.xctrunner"
info["CFBundleDisplayName"] = "Locus Speed Helper"
info["CFBundleShortVersionString"] = "1.0"
info["CFBundleVersion"] = "1"
info["NSLocalNetworkUsageDescription"] = "Receives simulated location, speed, and course from Locus on this iPhone."
info_path.write_bytes(plistlib.dumps(info, fmt=plistlib.FMT_BINARY))
PY
cp "$helper_root/LICENSE" "$helper_app/WebDriverAgentLicense.txt"
helper_package="$(mktemp -d "$helper_root/helper-ipa.XXXXXX")"
trap 'rm -rf "$helper_package"' EXIT
mkdir -p "$helper_package/Payload"
cp -R "$helper_app" "$helper_package/Payload/"
ditto -c -k --sequesterRsrc --keepParent "$helper_package/Payload" \
  "$helper_dist/Locus-Native-Speed-Helper-unsigned.ipa"
echo "Created Locus-Native-Speed-Helper-unsigned.ipa (XCTest helper; needs developer launch)."
