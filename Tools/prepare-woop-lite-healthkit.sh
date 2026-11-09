#!/usr/bin/env bash
# Embed a discoverable HealthKit capability request in the app-only Lite bundle. This ad-hoc
# signature is replaced by the installing sideloader; it grants no Apple provisioning rights.
# Run after removing Watch, extensions and optional resources, before creating the IPA.
set -euo pipefail

WOOP_APP="${1:?usage: $0 path/to/Woop.app}"
test -f "$WOOP_APP/Info.plist" || { echo "App Info.plist missing" >&2; exit 1; }
test ! -e "$WOOP_APP/Watch" || { echo "Lite bundle still contains Watch" >&2; exit 1; }
test ! -e "$WOOP_APP/PlugIns" || { echo "Lite bundle still contains extensions" >&2; exit 1; }

WOOP_SIGNING_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/woop-healthkit.XXXXXX")"
trap 'rm -rf "$WOOP_SIGNING_TEMP"' EXIT
cat > "$WOOP_SIGNING_TEMP/request.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>com.apple.developer.healthkit</key><true/>
    <key>com.apple.developer.healthkit.access</key><array/>
</dict></plist>
PLIST

# The app-only variant requests neither shared App Groups nor HealthKit background delivery.
# Foreground HealthKit still needs the installing tool to provision the App ID appropriately.
codesign --force --deep --sign - "$WOOP_APP"
codesign --force --sign - --entitlements "$WOOP_SIGNING_TEMP/request.plist" "$WOOP_APP"
codesign -d --entitlements :- "$WOOP_APP" > "$WOOP_SIGNING_TEMP/embedded.plist" 2>/dev/null
python3 - "$WOOP_SIGNING_TEMP/embedded.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], 'rb') as source:
    entitlements = plistlib.load(source)
expected = {
    'com.apple.developer.healthkit': True,
    'com.apple.developer.healthkit.access': [],
}
if entitlements != expected:
    raise SystemExit('Lite HealthKit capability request did not survive ad-hoc signing')
PY
codesign --verify --deep --strict "$WOOP_APP"
echo "HealthKit request embedded. The installer must provision and preserve this capability."
