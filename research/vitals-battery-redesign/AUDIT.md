# Battery tab design audit: Nov 11

Method: two isolated reviewers. A did the design review and the build-prompt check. B ran the Impeccable detector on `final.html` and measured contrast. Both looked at the mockup, not the app; nothing is built yet.

## Score: 22/32
Two heuristics are not applicable (n/a), so the maximum is 32.

| # | Heuristic | Score | Note |
|---|---|---|---|
| 1 | Status | 4 | Charge, state, trend and time left show at once |
| 2 | Real-world words | 3 | The energy title claimed Apple's measure |
| 3 | Control | n/a | Read-only tab |
| 4 | Consistency | 2 | The Overview tile and this tab worded the state differently; low-battery red was not stated |
| 5 | Error prevention | n/a | Nothing to get wrong |
| 6 | Recognition | 3 | The chart had no midline |
| 7 | Flexibility | 2 | Cycles were tooltip-only, so VoiceOver couldn't reach them |
| 8 | Minimal | 3 | A green card for "nothing wrong" |
| 9 | Error recovery | 2 | No wording for warning, problem or unknown health |
| 10 | Help | 3 | Fine |

## Fixed (in `final.html`/`final.png` and `prompts/vitals-battery-tab.md`)
- **P0, dishonest title.** "Using significant energy" covered only Evan's apps, and the mockup's example, Spotlight, can't be measured. It is now "Your apps using the most energy", with a tooltip saying macOS's own processes aren't included, and measurable example apps.
- **P1, misleading limit wording.** "Charged to N% limit" now shows only at the limit. Below it while charging, the line reads "Charging to N% limit".
- **P1, missing health words.** Each state now has wording: normal, holds less charge, needs service, unknown.
- **P2, low battery.** Red at 10% or less, matching the Overview.
- **P3, health card.** The green card when health is fine is now one quiet line. Cycles and condition go in the tooltip and VoiceOver.
- **Prompt:**
  - Parse `pmset` only while the tab is open, with a 5 s timeout, discarding non-charge lines.
  - Read the plist on open or when the power source changes.
  - "Charging on hold" is dropped unless documented.
  - Energy threshold 1 W, after 5 readings.
  - One shared status sentence (Words.battery).
  - `--simulate-battery` states, `--selftest-battery`.
  - Update the contract's Runtime, Privacy and CLI sections.
- **Contrast (detector, light mode).**
  - Grey text was 4.1:1 and the green check 2.4:1. The mockup is now darkened.
  - The prompt says use `.secondary` and the shared status green.

## Suppressed
- `cramped-padding` on the tab bar in `final.html` only. It stands in for the native segmented control, which sets its own insets.

## Left open (Evan's call)
- When plugged in at the limit with nothing wrong, should the tab skip the chart?
- Should energy ranking live on Processes instead?
