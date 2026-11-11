Redesign the Battery tab (Sources/Vitals/Views/BatteryTab.swift). The design was done in ~/Design: read ~/Design/research/vitals-battery-redesign/README.md and AUDIT.md, and look at final.png (the target), today-dark.png (today) and directions.png. Read CONTRACT.md first; its honesty, privacy and look rules win over the mockup. The mockup is HTML: match its layout and words, but use the app's own components (Module, StatusGlyph, glassButton, Theme text styles and colours, SF Pro Rounded figures, Swift Charts like CPUChart). Use the system .secondary style for every grey (the mockup's custom greys fail contrast in light mode), and the shared status green for the check (the mockup's light green is 2.4:1).

What to build:
1. Charge card.
   - Big charge % in rounded type. Beside it, on battery: "About 4 hr 10 min left". While charging: "Full in 40 min". Leave it out when macOS gives no estimate or is still calculating (-1).
   - At 10% or less on battery, the figure and status line turn red, matching the Overview's BatteryGauge. Nothing else gets colour.
   - Under it, one status line, built in Words.battery so the Overview tile, its tooltip and this tab say the same thing:
     - "Charged to N% limit" only when plugged in, not charging, and charge >= N-1. The limit comes from /Library/Preferences/com.apple.powerd.charging.plist: a ChargeCtrlPolicy with reason manualChargeLimit, N = soclimit.
     - "Charging to N% limit" while charging below it.
     - "Charging", "On battery".
     - Otherwise "Plugged in, not charging".
   - Read the plist on tab open and when the power source changes, not on every tick. If it is missing or unreadable, fall back silently.
   - The plist's `policies` value is an NSKeyedArchiver blob whose class (ChargeCtrlPolicy) is private. Decode it with PropertyListSerialization and read the `$objects` array for `reason` and `soclimit`. Never instantiate the private class or use NSKeyedUnarchiver on it. The same object has `noChargeToFull` and `isEndOfCharge`; note what they read in each state, but don't build on them.
   - Copy Apple's exact words: Settings and the menu bar say "Charged to 95% Limit", with a capital L.
   - Low Power Mode: when ProcessInfo.isLowPowerModeEnabled is true, add "Low Power Mode is on" under the status line. Use the public API, no polling; listen for NSProcessInfoPowerStateDidChange.
   - Optimized Battery Charging is on for Evan (Settings > Battery > Charging), so macOS can pause at 80%. If you can't detect that state from a documented signal, the "Plugged in, not charging" fallback covers it.
   - Never infer a reason from NotChargingReason bits. Leave "Charging on hold" out of code, snapshots and the contract unless you find a documented signal.
2. A summary line ("Up from 41% at 9:05 AM" / "Down 33% since 2:10 PM"), then a last-24-hours charge chart.
   - Draw it as one line (see final.png and chart-final.png; the shape is in research/vitals-battery-redesign/chart-final.js):
     - One ink (.primary) at one weight (2 pt), with round caps and joins. Smooth it with monotone cubic interpolation so it never overshoots a reading; Swift Charts' `.interpolationMethod(.monotone)` does this.
     - Y scale fixed at 0 to 100%, with no gridlines and no y labels. A single baseline only, and a plot about 72 pt tall.
     - Three time labels in .secondary under the baseline: the start (e.g. "6 PM"), the middle and "Now".
     - Mark one moment with a dot: the time it was plugged in (the low point, labelled "41%" on its left in .primary and "Plugged in" on its right in .secondary), or, on battery, the time it was unplugged ("Unplugged" above the dot). Add a dot at Now.
     - Where there are no readings (asleep), leave a clean break. No dotted bridge, and no drop to zero.
     - No bars, no bands, no charging strip and no green. Blind reads and Evan rejected the Apple-style 15-minute bars as ugly at this size (Nov 11).
   - One VoiceOver label, e.g. "Last 24 hours: 41% at 9:05 AM, now 95%, plugged in since 9:05 AM".
   - History source: `pmset -g log`. Parse it only while the Battery tab is showing and the cache is older than 10 min, never while the panel is closed. Run it off the main thread with a 5 s timeout. Stream the output and keep only the last 24 h of "Charge: NN" and AC/battery lines; discard everything else, since it names processes.
   - Merge in Vitals' own battery readings since launch, kept in memory only. If the parse fails, show only those readings; missing time stays empty.
3. "Your apps using the most energy" card, on battery only.
   - Evan's own apps, grouped with their helpers like the Processes tab does. Rank them by proc_pid_rusage RUSAGE_INFO_V6 ri_energy_nj deltas.
   - Show an app only if it averages at least 1 W over the readings so far. Names only, no numbers, up to 3, one line each with the full name in the tooltip.
   - Wait for at least 5 readings (10 s) before showing the card, and reserve no space for it before then. Hide it when none qualify.
   - Tooltip: "macOS's own processes aren't included."
   - Sample only while the panel is open and on battery, reusing the existing process tick. Add no polling while the panel is closed.
4. Health line, no green card when fine.
   - Fine: one quiet line at the bottom, "Holds 99% of its original charge", with cycle count and condition in its tooltip AND its accessibilityValue.
   - Warning: "Battery holds less charge". Problem: "Battery needs service" (use macOS's condition word). Unknown: "Battery health unknown". These show as a Module with StatusGlyph and the check's detail sentence.
   - Today batteryCheck's title is always "Battery health", so add these words in the view or in Words, not by editing Models.swift.
5. "Battery Settings…" as a normal glass button. It must not look dimmed like today's.
Cut: the Power source row, watts, adapter, the cycle row and the divider. Keep the "No battery" and "Checking battery" messages.

Feasibility was probed on this Mac on Nov 11: ri_energy_nj worked for all of Evan's processes and gave EPERM for most root ones (so e.g. Spotlight indexing and WindowServer can't appear); the powerd plist showed manualChargeLimit at 95; pmset -g log had about 2,987 charge readings over 7 days. Re-check each of these before relying on it.

Testing and contract:
- Add `--simulate-battery limit|charging|on-battery|low|worn|no-history` to --snapshot and --live-snapshot, plus #Previews for the same states.
- Add `--selftest-battery` to scripts/check.sh. It parses a saved pmset sample with gaps and a daylight-saving change, and tests the status-line and limit rules.
- Update CONTRACT.md: the Battery tab section, Runtime behaviour (the new reads and when they run), Privacy (the pmset shell-out and the powerd plist read), and the CLI section (the new flags).
- Work on a branch, run ./scripts/check.sh and open a PR.
- Verify with --live-snapshot --running-app --tab battery in light and dark, plus each simulated state. Say which pictures are the real window.
- Don't merge or install until I say mnd.
