# Vitals audit, 2026-11-07

Second look at `~/claude/vitals`, four days and 41 commits after the [11-03 audit](../README.md). New since then: Chip and Battery tabs, Smart Check (with a data globe), hide-a-warning, Copy for Claude, manual refresh, a stay-open panel.

Installed build = `main` at `f3434f6` (both Nov 6, 02:52). Screenshots are from its `--snapshot` mode, every tab in light and dark, plus `--simulate-disk-fill urgent`. `dump.json` and `smart-check.json` are from the same few minutes. Nothing in the app was changed.

Reviewed by an independent agent against the code, `CONTRACT.md` and the screenshots; its corrections are folded in (see [Review](#review)).

## Verdict

- **impeccable (native): 15/20, Good.** Accessibility 3, Performance 4, Colour 3, Native feel 3, Fit 2. Native verdict: pass.
- **11-03 was 16 before fixes and a self-scored 20 after; now 15.** The fixes held; the new features brought back helper text, duplicate figures, and a status colour that means two things.
- **Figures are right.** Every check in `dump.json` matches the machine. The problem is what the header and Smart Check *say* about them.

## P1: true before pretty

1. ~~**A hidden problem disappears everywhere, and the header says "Good".**~~ Fixed 11-07 `eac8c29` (branch `fix/truth-2026-11-07`): the word is "1 hidden"; Smart Check lists hidden checks, dimmed, "Hidden". See `after-truth/`. `backup` is a `problem` (Time Machine isn't set up). Evan hid it, so:
   - the header drops to a grey "Good". Documented (`CONTRACT.md:55`), but grey "Good" is also defined as "a check couldn't run" (`CONTRACT.md:52`, `Theme.swift:89`), so grey means two things;
   - Smart Check's "Also needs a look" filters hidden checks out (`SmartCheckRunner.swift:222`) and its verdict is the header's "Good". The finished card never mentions backups.

   Fix: a hidden problem keeps the word honest ("1 hidden" beside the grey dot, never "Good"), and Smart Check lists hidden problems as hidden rather than dropping them. Rewrite `CONTRACT.md:52/55` with it.
2. ~~**The scan's big number is mostly caches.**~~ Fixed 11-07 `eac8c29`: "338 MB to clear", Biggest wins rule. "36.0 GB" under the globe is `measuredBytes`, every folder measured (`SmartCheckRunner.swift:25`); 35.7 GB of it is "Rebuilds itself", which the card then says not to clear. The biggest figure on the screen is the least useful one. Show what you could clear, or label it.
3. ~~**The running line ends in a dangling dot in the live app.**~~ Fixed 11-07 `eac8c29`; the running snapshot no longer fakes a figure. In the snapshot it reads "Performance · Memory, heat, battery and disk", but that text exists only in `previewRunning` (`SmartCheckRunner.swift:196`). Live, `liveFigure` is nil during Protection and Performance (`:112`), so it reads "Performance · " (`SmartCheckCard.swift:119`). The snapshot hides a live bug.

## P2: clarity

4. **Smart Check's numbers look like a wrong sum.** Storage row: "Up to 338 MB you could clear" (storage-stage wins only, `SmartCheckRunner.swift:266`). Biggest wins below it: 338 + 146 MB from all stages (`SmartTypes.swift:65`). Label each win's stage, or make the row the total of what's listed.
5. **Battery is in four places.** Overview tile, Battery tab, Health `battery-health`, Smart Check Performance. The tab says "on battery" three ways and is half empty. Health already has capacity and cycles (`HealthChecker.swift:832`); the Overview tile already shows time left when it fits (`OverviewTab.swift:348`). Only "Condition" and "Open Battery settings" need a new home (the Health battery row). Changes `CONTRACT.md:98-100` and drops `--tab battery`.
6. **Five tabs plus Smart Check taking over Overview** (`SmartCheckCard.swift:18`): six screens behind a control that already had to shrink (11-04 audit). With Battery folded in, four tabs fit at regular size.
7. **Helper text is back** (11-03 item 12 cut it): "All cores", "Whole GPU", "Short on-demand recording". (Kept on purpose, not to cut: the illustration caption, "Possible…", the uptime "since", "Rebuilds itself".)
8. **Chip tab repeats Processes.** "Busiest processes" is the top three rows of the next tab. Cut it.
9. **Process names mix rules.** `trustd` → "Certificate checks", Spotlight grouped, but `accountsd`, `dataaccessd`, `loginwindow`, `ScreenTimeAgent` raw. `contactsd` → "Contacts", `CalendarAgent` → "Calendar", `remindd` → "Reminders" (`ProcessMonitor.swift:233-237`) read as the apps being open. Friendly names only when they can't be mistaken for an app.
10. **"Disk space" can be hidden at 3% free.** Only the filling-fast alarm is protected (`VitalsModel.swift:169`). Decide whether a nearly full disk can be silenced.
11. **`CONTRACT.md` is already out of date.** Still says three tabs, Overview / Processes / Health (lines 3, 52), and "13 checks" where the app has 14. Fix before the changes above add to it.

## Ask Evan (his contract decisions)

These go against the ethos, but each was asked for and written into `CONTRACT.md`. They need his call, not a fix:

- **Paced scan** (`CONTRACT.md:117`, "too fast and boring"). Padding is 7.3 s here (8 folders × 0.35 s + 5 stages × 0.9 s, `SmartCheckRunner.swift:33`), on top of the real work, which in the app includes the slow-check refresh. Results arrive about 9 s after clicking, for a ~1 s scan.
- ~~**Globe wedges at least 5% wide**~~ Moot 11-07: Evan, "i hate the globe it makes no sense"; globe removed in vitals#15 (`507d1bd`), see `no-globe/`. (`CONTRACT.md:118`). The two blue wins (484 MB) look like a large slice of a 36 GB sphere; in fact they are 1.3%.
- **Prominent blue Check button** (`CONTRACT.md:50`): the loudest thing on a calm Overview, louder than the status. The card is ~100 pt for one button.

## P3: polish

12. Copy-for-Claude buttons in Biggest wins are icon-only (specified, `CONTRACT.md:110`; VoiceOver label exists, `SmartCheckCard.swift:341`).
13. In the disk-alarm state the CPU history shrinks to ~50 pt and the "100%" label floats mid-chart (`overview-urgent-light.png`).
14. Health's all-clear with only hidden items uses the ⓘ glyph (`HealthTab.swift:298`), the same as Smart Check's FYIs. Settle it together with item 1.

## Not reviewed

The Hide / Unhide controls (snapshots draw the full list closed), the gear menu, VoiceOver beyond labels in code, Increase Contrast, Reduce Transparency, larger text. Re-render with the Health list open before the re-audit.

## Still working well

- One severity scale holds for *active* problems: urgent disk shows red dot, red tile, red "Needs attention".
- Contrast fixes from 11-04 hold in both appearances; system text styles and SF Symbols throughout.
- Reduce Motion skips the pacing and stills the globe; the globe is hidden from VoiceOver and the card carries the label.
- Smart Check findings are careful: "up to", "Possible", "Check before removing", cleanup hints rather than a Delete button.
- Every check figure matches macOS.

## Order of work

1. **Truth:** 1 (header word + Smart Check's hidden gap), 2, 3, then 4.
2. **Ask Evan:** pacing, 5% wedges, Check button.
3. **Fix the contract first:** 11.
4. **Distill:** 5 and 6 together (contract tab list, Battery section, `--tab battery`, check count in one change).
5. **Cut:** 7, 8, 9, decide 10.
6. **Polish:** 12–14; re-render with Health open; re-audit.

## Review

An independent agent checked items against code, contract and screenshots. Changes it made to the first draft:

- **Added** item 1's Smart Check half, item 3 (live dangling dot), 10 (hideable full disk), 11 (stale contract), and the globe's 5% minimum.
- **Moved to "Ask Evan":** pacing (it's in the contract at his request; first draft also said 7–8 s from the 1.5 s CLI run, which skips the in-app refresh) and the Check button.
- **Downgraded** the 338 / 484 MB sum from P1 to P2; item 2 upgraded (the counter is 99% caches, not just unlabelled).
- **Dropped:** "3 of 3 protections" (Protection is the contract's "by macOS" group; the real gap is item 1), grouping cores 4 | 6 (the app deliberately doesn't guess which core is which, `PerformanceTab.swift:125`), "No devices" icon (missing should look missing), four helper-text entries that are contract choices.

## Files

Light/dark: `overview`, `performance` (Chip tab), `processes`, `battery`, `health`, `check` (Smart Check done), `check-running`. Plus `overview-urgent-light.png`, `health-urgent-dark.png`, `dump.json`, `smart-check.json`.
