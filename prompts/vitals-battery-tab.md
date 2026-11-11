Redesign the Battery tab (Sources/Vitals/Views/BatteryTab.swift). The design was done in ~/Design. The target is a real SwiftUI file, so port it rather than redraw it.
- Read ~/Design/research/vitals-battery-redesign/README.md (the "Battery object, Nov 11" section) and AUDIT.md.
- Look at swiftui/battery-object.png and the renders in swiftui/out/: at the limit, on battery and charging, in light and dark.
- Code to port: swiftui/BatteryDesign.swift. Its BatteryObject, DayLine and BatteryTabDesign views are the layout, sizes and words to match.
- Read CONTRACT.md first. Its honesty, privacy and look rules win over the design file.
- Use the app's own pieces: Module, StatusGlyph, glassButton, the Theme text styles and colours, and SF Pro Rounded figures. The design file fakes these, for example a plain capsule for the button.
- Use the system .secondary style for every grey, and the shared status green and red.

What to build, top to bottom:
1. Charge module (padding 16).
   - Charge figure and battery, side by side.
     - The figure: 44 pt semibold rounded, monospaced digits.
     - The battery, about 48 pt tall, fills the rest of the row. Draw it as a real object: a rounded shell with a 2 pt hairline, a small cap on the right, and one flat fill whose width is the charge.
     - No gradients, gloss or glow.
   - Fill colour, the only colour on the tab:
     - Green while charging (Apple's battery convention).
     - Red at 10% or less on battery. The figure turns red too, matching the Overview's BatteryGauge.
     - Otherwise a neutral grey: white 0.86 in dark, 0.46 in light.
   - Charge limit:
     - Below the limit, draw a 2 pt mark inside the battery at the limit, with a small "Limit" caption2 centred above it.
     - At the limit, draw no mark and no caption. The status line already says it.
     - With no limit, draw nothing.
   - Status line, 15 pt medium, built in Words.battery so the Overview tile, its tooltip and this tab say the same thing:
     - "Charged to N% Limit" only when plugged in, not charging, and charge >= N-1. Copy Apple's capital L.
     - "Charging to N% Limit" while charging below it.
     - "Charging" and "On battery".
     - Otherwise "Plugged in, not charging".
     - Join the time estimate with " · ": "On battery · About 4 hr 10 min left" or "Charging to 95% Limit · Full in 45 min".
     - Leave the estimate out when macOS gives none or is still calculating (-1).
   - Where N comes from:
     - N comes from /Library/Preferences/com.apple.powerd.charging.plist: a ChargeCtrlPolicy with reason manualChargeLimit, N = soclimit.
     - Read the plist when the tab opens and when the power source changes, not on every tick. If it is missing or unreadable, fall back silently.
     - `policies` is an NSKeyedArchiver blob of a private class. Decode it with PropertyListSerialization and read the `$objects` array. Never instantiate the class or use NSKeyedUnarchiver on it.
   - Low Power Mode: when ProcessInfo.isLowPowerModeEnabled is true, add "Low Power Mode is on" under the status line. Listen for NSProcessInfoPowerStateDidChange instead of polling.
   - Optimized Battery Charging can pause at 80%. Without a documented signal, the "Plugged in, not charging" fallback covers it.
   - Never infer a reason from NotChargingReason bits.
   - Summary line in .secondary callout: "Up from 41% at 9:05 AM" or "Down 33% since 2:10 PM".
2. Last-24-hours chart, inside the same module, about 96 pt tall (see DayLine).
   - One line, .primary, 2 pt, round caps and joins, `.interpolationMethod(.monotone)`. Y fixed 0 to 100.
   - No y axis, no gridlines, no area fill, no dots, no bars, no green.
   - The limit: a 1 pt dashed rule ([2, 3], primary at 0.35), with a small "95%" caption2 at its right end. Leave it out with no limit.
   - Three x labels in .secondary caption2: the start ("Yesterday", or the start hour), the middle and "Now". The end labels align to the edges.
   - Where there are no readings (asleep), leave a clean break, using separate series. No dotted bridge, and no drop to zero.
   - One VoiceOver label, e.g. "Last 24 hours: 41% at 9:05 AM, now 95%".
   - History source: `pmset -g log`.
     - Parse it only while the Battery tab is showing and the cache is older than 10 minutes, never while the panel is closed.
     - Run it off the main thread with a 5 s timeout.
     - Stream the output and keep only the last 24 h of "Charge: NN" and AC/battery lines. Discard everything else, since it names processes.
     - Merge in Vitals' own readings since launch, kept in memory only. If the parse fails, show only those readings.
3. "Your apps using the most energy" module, on battery only.
   - Up to 3 rows, 26 pt tall: the app's real icon at 22 pt from NSWorkspace, then the name. Names only, with no numbers or bars. The full name goes in the tooltip.
   - Evan's own apps, grouped with their helpers as the Processes tab does. Rank them by proc_pid_rusage RUSAGE_INFO_V6 ri_energy_nj deltas.
   - Show an app only if it averages at least 1 W.
   - Wait for 5 readings (10 s) before showing the module, and reserve no space before then. Hide the module when no app qualifies.
   - Module tooltip: "macOS's own processes aren't included."
   - Sample only while the panel is open and on battery, reusing the existing process tick.
   - The design file shows the module in every state for review; build it on battery only.
4. Footer row, outside the modules.
   - Left: a small green check, then "Holds 99% of its original charge" in .secondary callout.
     - Put cycle count and condition in its tooltip and its accessibilityValue.
     - Warning: "Battery holds less charge". Problem: "Battery needs service" (use macOS's condition word). Unknown: "Battery health unknown". These replace the line with a Module that has a StatusGlyph and the check's detail sentence.
     - batteryCheck's title is always "Battery health", so add these words in the view or in Words, not in Models.swift.
   - Right: "Battery Settings" as a normal glass button. No ellipsis, and it must not look dimmed like today's.
5. Cut: the Power source row, watts, adapter, the cycle row and the divider. Keep the "No battery" and "Checking battery" messages. The tab ends where its content ends.

Feasibility was probed on this Mac on Nov 11:
- ri_energy_nj worked for Evan's processes and gave EPERM for most root ones.
- The powerd plist showed manualChargeLimit at 95.
- pmset -g log had about 2,987 charge readings over 7 days.
Re-check each of these before relying on it.

Testing and contract:
- Add `--simulate-battery limit|charging|on-battery|low|worn|no-history` to --snapshot and --live-snapshot, plus #Previews for the same states.
- Add `--selftest-battery` to scripts/check.sh. It parses a saved pmset sample with gaps and a daylight-saving change, and tests the status-line, limit-mark and fill-colour rules.
- Update CONTRACT.md:
  - The Battery tab section, including the fill colour as a status: green when charging, red when low.
  - Runtime behaviour: the new reads and when they run.
  - Privacy: the pmset shell-out and the powerd plist read.
  - CLI: the new flags.
- Work on a branch, run ./scripts/check.sh and open a PR.
- Verify with --live-snapshot --running-app --tab battery in light and dark, plus each simulated state. Put them next to swiftui/battery-object.png, and say which pictures are the real window.
- Don't merge or install until I say mnd.
