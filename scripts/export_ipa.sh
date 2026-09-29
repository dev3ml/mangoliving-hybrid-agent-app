#!/usr/bin/env bash
set -euo pipefail

# Builds a signed App Store IPA for Transporter / TestFlight.
# Prerequisite: App Store Connect app + bundle ID com.mangoliving.agent exist.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

flutter pub get
flutter build ipa \
  --release \
  --export-options-plist=ios/ExportOptions.plist

echo
echo "IPA ready:"
ls -1 build/ios/ipa/*.ipa
echo
echo "Drop that file onto Transporter."
