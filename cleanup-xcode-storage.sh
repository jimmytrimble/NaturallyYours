#!/usr/bin/env bash
#
# cleanup-xcode-storage.sh
# Reclaims disk space from regenerable Xcode / iOS Simulator caches that show up as
# macOS "System Data". Everything removed here is rebuilt automatically by Xcode on
# the next build / device connect / simulator run.
#
# What it does NOT touch:
#   - Your project, repo, or git
#   - Your app Archives (~/Library/Developer/Xcode/Archives) — kept for crash symbolication
#   - Installed simulator *runtimes* (iOS versions) — removing those is a big re-download,
#     so it only lists them and tells you the manual command.
#
# Usage:  ./cleanup-xcode-storage.sh
# Tip:    quit Xcode and the Simulator first for the fullest cleanup.

set -u

DERIVED="$HOME/Library/Developer/Xcode/DerivedData"
DEVICESUPPORT="$HOME/Library/Developer/Xcode/iOS DeviceSupport"
PREVIEWS="$HOME/Library/Developer/Xcode/UserData/Previews/Simulator Devices"
DOCCACHE="$HOME/Library/Developer/Xcode/DocumentationCache"

free_space() { df -h / | awk '/\/$/{print $4}'; }

echo "Free space before: $(free_space)"
echo

# 1) Shut down + erase simulators (clears each simulator's MobileAsset/AssetsV2 caches)
echo "→ Shutting down simulators..."
xcrun simctl shutdown all >/dev/null 2>&1

echo "→ Removing unavailable simulators..."
xcrun simctl delete unavailable >/dev/null 2>&1

echo "→ Erasing simulator content/caches..."
xcrun simctl erase all >/dev/null 2>&1

# 2) Build intermediates (always regenerated)
echo "→ Clearing DerivedData..."
rm -rf "${DERIVED:?}/"* 2>/dev/null

# 3) Debug-symbol caches from connecting physical iPhones (rebuilt on reconnect)
echo "→ Clearing iOS DeviceSupport..."
rm -rf "$DEVICESUPPORT/"* 2>/dev/null

# 4) SwiftUI Previews simulator cache
echo "→ Clearing SwiftUI Previews cache..."
rm -rf "$PREVIEWS/"* 2>/dev/null

# 5) Documentation cache
echo "→ Clearing documentation cache..."
rm -rf "${DOCCACHE:?}/"* 2>/dev/null

echo
echo "Free space after:  $(free_space)"
echo

# Informational: installed iOS runtimes (NOT deleted automatically)
echo "Installed simulator runtimes (each ~8 GB). These were left in place:"
xcrun simctl runtime list 2>/dev/null | grep -E "iOS |tvOS |watchOS |visionOS " || echo "  (none)"
echo
echo "To remove a runtime you don't need (frees ~8 GB each; re-downloadable in"
echo "Xcode → Settings → Components):"
echo "  xcrun simctl runtime delete <RUNTIME-ID>"
echo "  # or remove everything not currently usable:"
echo "  xcrun simctl runtime delete unusable"
