# Vitals Battery tab redesign: Nov 11

## Today (`today-dark.png`, real window)
Two cards of label/value rows and a dimmed-looking button. Half the panel is empty. It never says how long the battery will last, why it isn't charging, or what is draining it.

## Directions (`directions.png`, HTML mockups, not the app)
- A, Glance: big %, a charge bar, Power card (watts, adapter), three health tiles.
- B, Charge over time: big %, a charge chart, watts, one-line health.
- C, One card: a battery icon and a table.

Blind read (reviewer not told which was preferred): **B, then A, then C**. B answers all four questions: how much, how long, what's draining it, is it OK. Its fixes: say the held state in one line, label the chart's shading, explain or drop the app percentages, drop watts, and cut cycles from the health line.

## Research (two agents)
- **Other apps.** Apple says "Charging On Hold" and "Charged to [N]% Limit". Its menu lists apps "Using Significant Energy" by name, with no numbers. Settings' chart is fixed at 0 to 100% with charging stretches shaded, over the last 24 hours. Stats and iStat show a big %, a status, then history.
- **Readings on this Mac (probed, nothing changed):**
  - Per-app energy: `proc_pid_rusage` `RUSAGE_INFO_V6` `ri_energy_nj` works for Evan's own apps only. System processes give EPERM.
  - Why it isn't charging: `/Library/Preferences/com.apple.powerd.charging.plist` → `ChargeCtrlPolicy` `reason=manualChargeLimit`, `soclimit=95`. `NotChargingReason` bits are undocumented.
  - Adapter: `IOPSCopyExternalPowerAdapterDetails` (Watts, Name, which has a trailing space).
  - 24 h history: `pmset -g log` "Charge: NN" lines. No root needed, about 7 days, uneven times, about 74k lines.
  - Watts: `PowerTelemetryData.SystemPowerIn` (mW), updated once a minute.
  - Battery temperature: already read in `ThermalReader`.
- Probe code is in this session's scratchpad (`batprobe/`). It isn't kept in this repo.

## Chosen design (`final.png`, `final.html`)
1. **Charge card**: big % in rounded type; time left beside it on battery ("About 4 hr 10 min left") or "Full in 40 min" while charging. Under it, one status line in Apple's words: "Charged to 95% limit", "Charging on hold", "Charging", "On battery", or "Plugged in, not charging" when the reason is unknown. Then a summary line ("Up from 41% at 9:05 AM", "Down 33% since 2:10 PM"), and the last 24 hours of charge: fixed 0 to 100%, plugged-in stretches as a neutral band labelled "Plugged in" (never green), and gaps left open.
2. **Using significant energy**: on battery only, Evan's own apps by energy over the last minute, names only, up to 3. Hidden when nothing is significant.
3. **Health**: status glyph plus "Battery health is normal", "Holds 99% of its original charge." Cycles and condition go in the tooltip. Warnings use the shared status scale (orange or red, `StatusGlyph`).
4. **Battery Settings…** as a normal glass button, not dimmed.

Cut: watts, adapter row, cycle row, temperature, the "Power source" row.

## What macOS Battery settings taught us (looked at Nov 11, read only, nothing changed)
- **Wording.** The header and the chart both say "Charged to 95% Limit", with a capital L. Vitals now copies it exactly.
- **Health.** Apple shows only Battery Condition ("Normal") and Maximum Capacity ("99%"), each with one plain sentence. It shows no cycle count, which backs cutting it from the tab.
- **Charging sheet.**
  - Charge Limit slider: 80, 85, 90, 95 or 100%. Evan's is 95%.
  - Optimized Battery Charging is on, so a pause at 80% can happen. Vitals falls back to "Plugged in, not charging" unless a documented signal exists.
- **Last 24 Hours chart.**
  - Battery Level is drawn as one bar per 15 minutes on a 0, 50 and 100% scale labelled on the right, with hour ticks along the bottom.
  - Charging is a green strip with a bolt under the axis, not a band behind the bars.
  - The design now uses the same layout in neutral grey, because Vitals keeps colour for status.
- **Last 10 Days.**
  - Energy Usage is the share of the battery used per day; Screen On Usage is hours per day.
  - Left to Settings: Vitals can't read screen time, and the panel is small. "Battery Settings…" opens it.
- **Low Power Mode** sits at the top of the pane. Vitals can read it through `ProcessInfo.isLowPowerModeEnabled` (public, no prompt), so the tab says "Low Power Mode is on" when it is.
- **Not used:** Options (dim the display on battery, wake for network access, and so on) are settings, not readings.
- **The powerd plist's `policies`** is an NSKeyedArchiver blob of a private class. Read it as a plain property list and never unarchive it.

## Chart, revised Nov 11 (after Evan called the 15-minute bars ugly)
The Apple-style bars were sent without a blind read; at 372 pt, 96 thin bars read as a barcode. Three options were then rendered (`chart-options.png`: soft-filled line, hourly bars, plain line) and blind-read twice. The plain line won.

It went through two rounds of fixes. The final version (`chart-final.png`, `chart-final.js`) is:
- One ink at one weight, with monotone smoothing so it never overshoots a reading.
- No gridlines, and three time labels.
- One marked moment: "41% · Plugged in", or "Unplugged".
- A clean break where there are no readings.
