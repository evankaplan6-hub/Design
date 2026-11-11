# Vitals Processes tab refresh: research, Nov 11

All pictures are real windows from `--live-snapshot` on branch `design/processes-refresh` (vitals repo), not look-alike renders. Numbers differ per picture because each is its own live sample. One row in B to E is drawn as if the pointer were over it.

## What other Mac monitors do
- Stats, Bresink System Monitor, iStat Menus 7: a short capped list (often 5) of the busiest processes, opened from the CPU item.
- MacStats and MōStats: helpers fold into their parent app; MacStats hides system daemons; MōStats offers Quit and flags apps macOS reports as not responding.
- Apple HIG (lists and tables): keep row text short, column headings as plain nouns, right-click menus for row actions. It gives no rule for hover-only buttons.
- None of them puts a Quit button on every row at rest.

## Directions tried (`four-directions.png`)
- A, today: table, dividers, Quit on every app row.
- B, calm table: no dividers, Quit only on the row under the pointer.
- C, load bars: B plus a thin CPU bar under each name.
- D, split: your apps in one card, background work in a quieter card below, Quit on hover, with bars.
- E (`today-vs-split.png`, light and dark): D without the bars.

## Blind read (a reviewer not told which was current)
Ranked D, B, A, C. The split answers "what could I quit" fastest. Bars read as underlines or a dotted rule and repeat the CPU number. Its one change to D: drop the bars. That is E.

## Trade-off to know
Splitting means a busy background process (Siri & suggestions at 32%) sits below an app at 4%. Each card is sorted by CPU, and the numbers stay bold, so it still stands out.

## Second pass, Impeccable 4.8.2 critique (same day)
An isolated reviewer scored today's tab 27/40 and overturned the split: D and E rank background work in a separate card, so Siri & suggestions at 32.5% sat under an app at 4.6%. For a monitor that is wrong, not just a style. Its pick: B (one list, one ranking, Quit on hover) with background rows quieted in place, figures under 1% in secondary text, hover and Quit only on rows that can quit, Quit also shown on keyboard focus, and a stronger hover in Increased Contrast. Bars: no (they repeat the number and clip at 100%).

## Decision and build
A third reviewer weighed both reads and chose B with background rows quieted in place: one CPU ranking, no split, no bars. Built on vitals branch `design/processes-refresh`. `built.png`: today, the new tab at rest, and with every quittable row forced into its hover state (light and dark; in use only the row under the pointer shows Quit).
