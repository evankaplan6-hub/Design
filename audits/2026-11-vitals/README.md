# Vitals audit, 2026-11-03

App: `~/claude/vitals` (Swift menu-bar app; spec in its `CONTRACT.md`). Two passes on the same build, merged here:

- **impeccable audit**: technical quality (accessibility, theming, native feel) plus a data check of every figure against macOS's own tools.
- **unslop audit**: does it look designed or templated. Web-only unslop rules (font list, weight cap, lucide, hero passes) left out; SF Pro, SF Symbols and system text styles stay.

Screenshots here are from the installed build's `--snapshot` mode (light/dark, plus `--simulate-disk-fill urgent`); `dump.json` is `--dump-json` from the same minute. Nothing in the app was changed.

## Verdict

- **impeccable: 16/20 (Good).** Accessibility 3, Performance 4, Colour 3, Native feel 3, Fit 3. Native verdict: pass.
- **unslop: light slop → polish mode.** No gradients, glows, emoji, hype, exclamation marks, uppercase tracked labels, looping motion or fake data; spacing on a 4 pt grid. What's left is template look: swap the name for iStat Menus or CleanMyMac's menu and the Overview still fits.
- **Figures are right.** CPU, memory, storage, battery, uptime, firewall, FileVault, Time Machine, SMART and per-app CPU all matched macOS. Temperature not checkable without sudo. The one wrong row is the family-tree backup (below).
- At audit time Vitals was **not running**, though disk-full warnings are on.

## How the two compare

| Topic | impeccable | unslop | Merged call |
|---|---|---|---|
| Health colours | P1: header orange/yellow vs rows red/orange | Signature: one status dot, one scale | Same fix. One severity scale everywhere |
| Rings | P2: full ring means busy, charge, or used-under-"Available" | Mini charts on stat tiles; decoration | Go further than consistency: drop the rings |
| Temperature | P2: headline not labelled as the chip | Loudest figure, least actionable | Label "Chip", demote to a normal figure |
| Extra labels | P3 list | Same list plus trailing periods | One cut list (below) |
| Health tab | P2: 3 screens, mostly green | not covered | Only what needs a look, plus one all-clear line |
| CPU chart | P3: VoiceOver gets no value | Should be the lead, now squeezed | Make it the lead; give it a VoiceOver summary |
| CPU number format | not covered | "5%", "3.7%", "11.9" | One format |
| Process names | P2: "(deleted)", raw daemon names | not covered | Keep |
| Data and logic | P1/P2: backup row, disk alarm, stale figures | not covered | First, before any look changes |
| Spacing, icons | not covered | Gauge padding 8 vs 12, Processes dead band, icons that repeat labels | Keep |

**Agreements:** both want one status colour scale, honest rings or none, a quieter temperature, and fewer labels. **Only unslop:** a lead chart, number formats, spacing, icons. **Only impeccable:** everything about whether the data is true, process names, Health length, accessibility.

**One tension:** rings are Apple-native (Battery widget, Activity rings), so removing them trades a native look for clarity. Recommend removing: four rings at 5%, a dot, half-full and 80% read as decoration, and the ethos says cut what doesn't carry meaning. `CONTRACT.md` ("four gauge modules") must change with it.

## Merged findings

### 0. Before anything
- ~~**No git history.**~~ Done 11-03: first commit `aca8288`.

### P1: true before pretty
1. ~~**Family-tree backup row says it worked when it failed.**~~ Done 11-03, `b781e4c` (also covers the 48 h part of item 10: warning after 26 h). Log has `RUN END BACKUP FAIL: CONFIG-CHANGED CLAUDE.md` on Nov 1 and 2; the parser only counts "FAILED", so "FAIL:" passes (and `STATUS FILE WRITE FAILED` would wrongly fail a good run). Read the `RUN END BACKUP OK/FAIL` line. `HealthChecker.swift:601`. Verified.
2. ~~**One severity scale.**~~ Done 11-03, `a5f81a7` (green / orange "Worth a look" / red "Needs attention" / grey "Good" when a check couldn't run). A `problem` row is red but the header says orange "Needs attention"; a `warning` makes the header a yellow "Good". Same word and colour everywhere: menu-bar dot, header, Health summary, rows, Overview card. This is also the product's signature. `Models.swift:208`, `Theme.swift:66`.
3. ~~**Disk alarm fires on a big download.**~~ Not a bug, 11-03 `ce7d6b5`: the 10 GB / 5 min rule is the deliberate catch for chunked fills (its own self-test needs it), so a long steady ≥34 MB/s download gets one warning. Kept; pinned by a new self-test; rule written into CONTRACT.md. Original note: The "10 GB fell in 5 min" start rule (not in the contract or self-test) triggers on a 40 MB/s download with 240 GB free. `DiskWatch.swift:206`. From code.

### P2: clarity
4. ~~**Rings → plain stat tiles**~~ Done 11-03 `d63d854`. (figure + label; status colour only on Warning/Critical/filling).
5. ~~**Temperature:**~~ Done 11-03 `d63d854`. label it "Chip", normal figure size.
6. ~~**One CPU format:**~~ Done 11-03 `d63d854`. whole % on Overview; Processes column shows %.
7. ~~**Process names:**~~ Done 11-03 `d63d854`. strip "(deleted)"; friendly names or a consistent rule for `triald`, `tccd`, `coreauthd`.
8. ~~**Health tab:**~~ Done 11-03 `d7bdc1d`. only what needs a look, then one all-clear line that expands. Cut sentences that repeat the title ("Firewall / Firewall is on.") and "✓ Protected".
9. ~~**CPU history as the lead:**~~ Done 11-03 `d63d854`. full width, taller, no "Filling in…" (missing history just looks empty), single 100% hairline instead of three axis labels; VoiceOver summary ("CPU 5%, peak 40% in the last 3 minutes").
10. **Stale or guessed figures:** (11-03 `23dd4e8`: network now fresh on open; battery condition unknown instead of assumed "Normal"; the 48 h backup part done in `b781e4c`. Left: disk episode can't clear while samples are sparse, which heals once regular sampling resumes, and a `statfs` failure would freeze it, which is very unlikely.) network rate on open is a 30 s average; battery fallback states guesses as fact; a missed nightly backup stays ok up to 48 h; a disk episode can freeze when samples gap or `statfs` fails.
11. ~~**Contract drift:**~~ Done 11-03 (each commit updated CONTRACT.md). `.numericText()` claimed but absent; disk-alarm start/clear rules differ from code. Update `CONTRACT.md` with every change above.

### P3: polish
12. ~~**Cut labels:**~~ Done 11-03 `d7bdc1d` and `d63d854`, except "Some macOS processes aren't shown", kept on purpose (true before pretty: the list really is missing root processes). "Last 3 min", "Filling in…", "CPU: % of one core", "Using the most CPU", "Name" column header, "Some macOS processes aren't shown", "Apple M5 · 16 GB" on every open; the laptop, chart and thermometer icons beside their own words; trailing periods on short strings ("Running cool.", "Backups.").
13. ~~**Spacing:**~~ Done 11-03 (tiles at 12 with the rings; Processes rows 42 pt close the gap; the 1 pt glyph nudge stays, it is optical). gauge tiles 8 → 12 like every other module; remove `padding(.top, 1)`, `spacing: 6`, `.scaleEffect(0.76)`; close the ~70 pt dead band on Processes.
14. ~~**Recommendation icon:**~~ Done 11-03 `d7bdc1d`. plain, no red tile.

## Direction (from unslop, fits the ethos)
- **Product:** a menu-bar check on Evan's MacBook that says plainly whether anything needs him, and proves it with real numbers.
- **Character:** plain-spoken, calm, exact.
- **World:** a bedside vitals monitor: one trace, a few figures, a light that's only on when someone should look.
- **Moment:** the CPU history, as the one trace.
- **Signature:** one status dot, one colour scale, everywhere.

## Working well
Honesty rules held (no RAM cleaner, pressure not % used, no false heat alarm). Polite Quit only. No protected folders, no network except the speed test. All 74 disk self-tests pass. System colours and text styles throughout; good in light and dark.

## Order of work
1. First git commit in `~/claude/vitals`.
2. **Truth** (impeccable harden): items 1, 3, 10.
3. **One scale** (colorize): item 2.
4. **Clarity** (clarify + unslop polish): items 4-7, 9.
5. **Distill** (distill + unslop polish): items 8, 12-14.
6. Sync `CONTRACT.md` (item 11), rebuild, re-render all tabs, re-run both audits.

## After the fixes (11-03, same day)

Seven commits in `~/claude/vitals` (`aca8288`..`d7bdc1d`). My re-score of the same five areas, not a fresh independent audit:

| Area | Before | After | Why |
|---|---|---|---|
| Accessibility | 3 | 4 | CPU chart has a VoiceOver value; tiles and the show-all row are labelled |
| Performance | 4 | 4 | unchanged |
| Colour | 3 | 4 | one status scale everywhere |
| Native feel | 3 | 4 | no rings meaning three things; system styles throughout |
| Fit | 3 | 4 | Health fits one screen; Processes fills the panel |

unslop: no slop signs left from the list; the template check now fails in the good way (one status scale as the signature, CPU history as the one lead chart).

Still open, all small: rare background processes without a plain name show their raw name; a disk-fill episode can't clear while samples are sparse or if `statfs` fails; the Health count line repeats the worst row's glyph.
