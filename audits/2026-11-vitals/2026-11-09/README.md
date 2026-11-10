# Vitals UI, UX and accessibility audit, 2026-11-09

App: `~/claude/vitals`, `main` at `8483962`, installed build from today. No Vitals code was changed.

## Verdict

**14/20 (Good), with one blocker.** The numbers and wording are honest and the app looks native. The weak spots are the newer screens (Smart Check most of all), VoiceOver feedback, and layouts that assume short content.

| Area | Score | Main finding |
|---|---|---|
| Accessibility | 2/4 | Buttons are labelled, but nothing is announced, and there are no headings |
| Performance | 4/4 | Fine in code; see the CPU reading in the checks table |
| Appearance and colour | 3/4 | Text contrast is strong; warnings are yellow in some places and orange in others |
| Native feel | 3/4 | Real macOS controls; some are too small, and key facts live only in tooltips |
| Fit and layout | 2/4 | Smart Check and Overview can run off the bottom of a panel that can't grow |

The 11-03 re-score was 20/20 before Smart Check, Memory, Chip and Battery existed. This is a fresh audit of all six tabs.

**Native feel: pass.** It reads as a real Mac app, not a web page in a window.

**VoiceOver: FAIL.** Headings are missing, and some status symbols have no spoken status.

**Contrast: FAIL for small graphics, PASS for text.** All text measured 5.0:1 or better. Some squares and status symbols fall below 3:1.

## What was checked

| Check | How | Result |
|---|---|---|
| All 6 tabs plus Smart Check, light and dark | `--snapshot` from the installed build, 23 renders | Done |
| Alert states | Simulated disk fill and memory pressure | Done |
| Worst-case data | Throwaway copy of the code in a scratch folder, fake long names and more results | Done |
| Control sizes | Real macOS controls measured off screen | Done. Layout sizes; the visible glass may be slightly larger |
| Contrast | Calculated from rendered pixels | Done |
| VoiceOver | Read from the code | **Not run with VoiceOver on** |
| Keyboard, Escape and arrow keys | Read from the code | **Not pressed.** Vitals' contract says never to click in the live panel |
| Glass and the real panel background | Snapshots use a plain grey stand-in | **Not measured.** Contrast on the real material can differ with the wallpaper |
| CPU use of the running app | One `ps` and one `top` reading, panel state not controlled | 0.0% in both, about 43-55 MB memory |

## P0: blocks you

### 1. Smart Check can hide its own Done button
- **Where:** `SmartCheckCard.swift:72-88`. The card has no scrolling.
- **What happens:** the panel is 620 pt tall. Today's real result is already about 18 pt too tall (`real-smart-check-today.png`). With three wins plus one "Also needs a look" row, **Check again and Done are gone** (`stress-smart-check-3-wins-no-done-button.png`). You have that "Also" row today because of the hidden backup warning. Opening "+N more" is worse (`stress-smart-check-expanded.png`).
- **Why it is a blocker:** Done is the only way back to Overview. Closing the panel doesn't clear the result, so you would have to quit Vitals.
- **Fix:** let the middle scroll, and pin Check again and Done below it.

## P1: fix next

### 2. One-click Quit sits on a list that reorders every 2 seconds
- **Where:** `ProcessesTab.swift:126`, `VitalsModel.swift:620`, `Actions.swift:88-89`.
- **What happens:** rows sort by live CPU, and a normal app quits with no question. The button measures 35 x 13 pt. A row can move under the pointer just as you click, so you can quit the wrong app. macOS still asks about unsaved work, so this is annoying more than destructive.
- **Fix:** freeze the order while the pointer is over the list, and make Quit bigger.

### 3. An old Smart Check result replaces Overview indefinitely
- **Where:** `SmartCheckRunner.swift:72` and `:182` are the only places that clear it. `SmartCheckCard.swift:45` and `:129` show a time with no date.
- **What happens:** finish a scan, close the panel, and days later Overview still opens on "Checked at 9:12 AM" instead of live figures. The time doesn't say which day.
- **Fix:** return to the normal Overview after the panel closes (or after a few minutes), and show the day when it isn't today. The refresh button's `lastCheckedText` already does this.

### 4. VoiceOver isn't told when things change
- **Where:** there are no announcements or focus moves anywhere in `Sources/Vitals`.
- **What happens:** pressing Check replaces the whole screen and the button you were on disappears (`SmartCheckSwitch`). Show all and Done on Memory do the same. Scan finished, Copied, Quitting, speed test results and refresh finished are all silent.
- **Fix:** announce finishes and move focus to the new content.

### 5. The recommendation card shows status by colour only
- **Where:** `OverviewTab.swift:59-65`. Also `BatteryTab.swift:34` and `HealthTab.swift:294`.
- **What happens:** the symbol depends on the check, not the severity. Orange or red is the only difference between a warning and a problem. VoiceOver reads the symbol's name instead of a status.
- **Fix:** give the symbol a spoken status ("Warning", "Problem"), and hide the decorative ones from VoiceOver. Health's rows already do this.

## P2: next pass

| # | Issue | Where | Fix |
|---|---|---|---|
| 6 | Must-know facts are only in tooltips: Test Speed can use several hundred MB, Show name triggers a location prompt, CPU is % of one core. Tooltips need a mouse and a wait | `OverviewTab.swift:625`, `:589`, `ProcessesTab.swift:20` | Put the costly ones on screen; keep tooltips for extras |
| 7 | Small controls. Mini 35 x 13 pt (Quit, +N more, Show all, Show name), Copy icon 20 x 22, tabs 20 tall. Apple's macOS minimum is 20 pt | `.controlSize(.mini)` in 5 places | Use small as the floor |
| 8 | Colour scale drift. Warnings are yellow on Health and Smart Check, orange in text, dots and on Battery. The contract says one scale. Yellow is only 1.21:1 on light modules | `Components.swift:210`, `Theme.swift:63`, `BatteryTab.swift:34-35` | Use orange in `StatusGlyph`; use `StatusGlyph` on Battery |
| 9 | Memory squares. Warning and Critical differ only by hue (1.55:1 against each other). Quiet is 1.30:1 and no-reading 1.76:1 in light mode | `MemoryTab.swift:171-176` | Add a shape or mark for Differentiate Without Color; darken quiet |
| 10 | Reduce Motion gaps. The repeating pulse, Health's expand, and the refresh icon swap don't check it, though other motion does | `OverviewTab.swift:63`, `HealthTab.swift:153`, `:186`, `PopoverView.swift:185` | Gate them like `RefreshButton`'s rotate |
| 11 | "1 hidden" as the headline. It is your status today, and Smart Check shows it large as the verdict. It doesn't say what is hidden | `Models.swift:223` | "1 warning hidden". Needs a `CONTRACT.md` edit |
| 12 | Only Memory's tile is clickable, and it looks like the other three until you hover | `OverviewTab.swift:261` | Link CPU to Chip and Battery to Battery, or add a chevron |
| 13 | Overview can push the footer off the panel. The comment says it can't | `OverviewTab.swift:29-32`, `stress-overview-worst-case.png` | Cap the recommendation at 3 lines, or let Overview scroll |
| 14 | Text can shrink to about 5.5-6 pt | `MemoryTab.swift:123`, `:401`, `ProcessesTab.swift:121`, `:124` | Stop at 0.85 and truncate instead |
| 15 | Escape always closes the whole panel, even from the device list or Show all. Escape and arrow keys look like they still act behind a Quit dialog (from code, not pressed) | `StatusItemController.swift`, `PopoverView.swift:46` | Let child views handle Escape; skip while a dialog is open |
| 16 | No headings for VoiceOver on any module title. The CPU core bars read as ten separate items | `Components.swift:246`, `:280`, `PerformanceTab.swift:109` | Add the header trait; group the bars |

## P3: polish

- **Chip tab:** the fixed chip specs take the top spot above live activity. The glow barely separates load (5% is 0.47 brightness, 30% is 0.74) and never stops pulsing unless Reduce Motion is on (`M5DieMap.swift:41-46`).
- **Button case:** "Test Speed" and "Shut Down" next to "Shut down", "Check again" and "Open Battery settings".
- **Small mismatches:** live rates list up then down, speed test lists down then up (`OverviewTab.swift:549`, `Theme.swift:297`). Wired networks show "Network (en7)" (`OverviewTab.swift:579`). Some process names are still raw (`UsageTrackingAgent`, `knowledge-agent`).
- **Battery:** one divider sits between only two of three rows (`BatteryTab.swift:40`).

## Patterns

- **Newer screens skipped the rules older ones follow.** Battery and Chip have their own spacing and status drawing. Smart Check has no scroll fallback.
- **Layouts are tuned to today's data.** A fixed-height panel needs a scrolling plan on every screen.
- **Tooltips carry too much.** That hurts keyboard and VoiceOver use most.

## What is working

- Text contrast is strong: 7.8-8.3:1 for secondary text, 5.0-7.1:1 for red text on alert washes.
- Every icon-only button has a spoken name. Row Quit is also a right-click and a VoiceOver action.
- Dangerous dialogs make Cancel the default and say exactly what will stop.
- Smart Check's motion and pacing respect Reduce Motion. The squares have a good spoken summary.
- Increase Contrast adds module outlines.
- Long names truncate cleanly on Processes and Memory, and the full name stays in the tooltip.
- The honesty rules still hold: no fake cleaning, no "% used", nothing deleted.

## Order of work

1. **P0 and P1 layout and behaviour:** items 1, 2, 3 (`/impeccable harden`).
2. **VoiceOver:** items 4, 5, 16 (`/impeccable harden`).
3. **Colour and motion:** items 8, 9, 10 (`/impeccable colorize`, `/impeccable animate`).
4. **Words and clarity:** items 6, 11, 12 (`/impeccable clarify`).
5. **Layout limits:** items 7, 13, 14, 15 (`/impeccable adapt`).
6. **Final pass:** `/impeccable polish`, then re-run this audit and do one real VoiceOver and keyboard run.

Vitals has no `PRODUCT.md`. `CONTRACT.md` covers most of it, so `/impeccable init` is optional.

## Addendum: measured on the real running app (same day, build `b3bff13`)

The audit above scored performance from code. These figures are from the installed app with its real panel open, measured by CPU time used over 4.4 seconds per tab, twice. Percent of one core.

| State | CPU |
|---|---|
| Panel closed | 0.0-0.2% |
| Overview | 2.5-2.7% |
| Chip | 20.8-21.1% |
| Memory | 1.6-2.0% |
| Processes | 1.8-2.3% |
| Battery | 1.1-1.6% |
| Health | 1.1-1.4% |

- **Chip is the outlier, about ten times the other tabs.** A 4-second sample shows the main thread busy 25% of the time, all of it redrawing and laying out the whole panel. The pulsing glow on the chip picture (`M5DieMap.swift:55`) is the only thing on that tab that redraws continuously, 12 times a second. Not proven by switching it off.
- Performance is 3/4, not 4/4, until that is fixed.
- Not measured: what macOS's window server spends drawing the glass, and Smart Check while it runs.
- The tab bar overflow (PR 23) was missed by this audit because every picture came from `--snapshot`, which draws look-alikes of macOS's own controls. Audits now use `--live-snapshot` on the real panel.

### After the fix (build `01f686f`, PR 25)

The pulse is now an animation macOS runs by itself. Same method, same running app:

| State | Before | After |
|---|---|---|
| Panel closed | 0.0-0.2% | 0.0-0.7% |
| Chip | 20.8-21.1% | 4.5-5.4% |
| Overview | 2.5-2.7% | 2.5% |
| Memory | 1.6-2.0% | 1.6% |
| Processes | 1.8-2.3% | 3.2% |
| Battery | 1.1-1.6% | 1.1% |
| Health | 1.1-1.4% | 1.4% |

- The main thread is busy 6% of the time on the Chip tab, down from 25%. What is left is the tab's live figures updating.
- `--selftest-livepanel` now fails if a tab left open uses 8% of one core or more.
