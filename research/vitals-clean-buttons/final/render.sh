#!/bin/sh
# Builds CleanButtonsDesign.swift against Vitals' own files at a pinned commit, read with
# `git show` (nothing in ~/claude/vitals is checked out or changed), then draws every screen
# offscreen into out/. Nothing opens on screen and nothing is cleaned.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
VITALS=${VITALS:-$HOME/claude/vitals}
REV=${REV:-a489c94}   # origin/feat/smart-check-clean-actions on Nov 14 2026
T=$(mktemp -d)
for f in SmartCheck/CleanEngine.swift SmartCheck/CleanController.swift SmartCheck/SmartSizer.swift \
         SmartCheck/SmartTypes.swift SmartCheck/AppLeftoverScanner.swift Models.swift BatteryHistory.swift \
         ProcessMonitor.swift Theme.swift Views/Components.swift; do
  git -C "$VITALS" show "$REV:Sources/Vitals/$f" > "$T/$(basename "$f")"
done
swiftc -parse-as-library -D DEBUG -target arm64-apple-macosx26.0 -o "$T/render" "$T"/*.swift "$HERE/CleanButtonsDesign.swift" </dev/null
"$T/render" "${1:-$HERE/out}"
rm -rf "$T"
