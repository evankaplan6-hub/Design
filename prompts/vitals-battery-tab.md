Redesign the Battery tab (Sources/Vitals/Views/BatteryTab.swift). The design was done in ~/Design: read ~/Design/research/vitals-battery-redesign/README.md and look at final.png (the target), today-dark.png (today) and directions.png. Read CONTRACT.md first; its honesty, privacy and look rules win over the mockup. The mockup is HTML: match its layout and words, but use the app's own components (Module, StatusGlyph, glassButton, Theme text styles, SF Pro Rounded figures, Swift Charts like CPUChart).

What to build:
1. Charge card. Big charge % in rounded type. Beside it, on battery: "About 4 hr 10 min left". While charging: "Full in 40 min". Leave it out when macOS gives no estimate. Under it, one status line in Apple's words:
   - "Charged to N% limit" when /Library/Preferences/com.apple.powerd.charging.plist has a ChargeCtrlPolicy with reason manualChargeLimit (N = soclimit).
   - "Charging on hold" if you find a reliable optimized-charging signal.
   - "Charging" or "On battery".
   - Otherwise "Plugged in, not charging". Never guess a reason from NotChargingReason bits; they are undocumented.
2. A summary line ("Up from 41% at 9:05 AM" / "Down 33% since 2:10 PM"), then a last-24-hours charge chart. The Y axis is fixed at 0 to 100%. Plugged-in stretches are a neutral band labelled "Plugged in", never green, because colour only means status. Don't bridge gaps. Axis labels "24 hr ago" and "Now" in secondary text, not tertiary. VoiceOver gets one summary label.
   History source: parse `pmset -g log` "Charge: NN" lines plus the AC/battery events (no root, about 7 days, about 74k lines). Run it off the main thread with a timeout, cache it, refresh at most every 10 min, and merge in Vitals' own battery readings since launch, kept in memory only. If the parse fails, the chart shows only Vitals' own readings, and missing time stays empty.
3. "Using significant energy" card, shown only on battery. Use Evan's own apps (group helpers like the Processes tab does), ranked by energy over the last minute from proc_pid_rusage RUSAGE_INFO_V6 ri_energy_nj deltas. Show names only, no numbers, up to 3, and only apps above a sensible threshold. Hide the card when none qualify. Sample energy only while the panel is open and on battery, reusing the existing process tick; add no new polling when closed.
4. Health card: StatusGlyph plus "Battery health is normal" (or the check's warning or problem title on the shared scale), and "Holds 99% of its original charge." Cycle count and condition go in the tooltip.
5. "Battery Settings…" as a normal glass button. It must not look dimmed like today's.
Cut: the Power source row, watts, adapter, the cycle row and the divider. Keep the "No battery" and "Checking battery" messages.

Feasibility was probed on this Mac on Nov 11: ri_energy_nj worked for all of Evan's processes and gave EPERM for most root ones; the powerd plist showed manualChargeLimit at 95; pmset -g log had about 2,987 charge readings. Re-check each of these before relying on it, and fall back quietly where one fails.

Update CONTRACT.md's Battery tab section to match. Add a #Preview and --snapshot states for plugged in at the limit, charging, and on battery with the energy list. Work on a branch, run ./scripts/check.sh, open a PR, and verify with --live-snapshot --running-app --tab battery (light and dark). Say which pictures are the real window. Don't merge or install until I say mnd.
