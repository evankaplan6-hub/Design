# Research: a creative scan graphic for Vitals' Smart Check

You're picking up a design research task for **Vitals**, Evan's native macOS menu-bar app (`~/claude/vitals`, SwiftUI, macOS 26+, Swift package built by `scripts/build-app.sh`). Read `~/claude/vitals/CONTRACT.md` and `~/Design/ETHOS.md` first. Evan is non-technical; write plainly.

## The question

What should the **Smart Check** scan look like while it runs? Evan wants something **creative**, not a plain progress bar or a stacked storage bar. It must also **make sense**: the graphic should show real results, not decoration.

## What Smart Check is

A button on the Overview tab. It scans five stages: Storage, Protection, Performance, Startup items, Apps. It finds folders you could clear ("wins") and caches that refill on their own. The real scan takes about 1.5 s. The live app paces the reveal to about 7–9 s on purpose (Evan, Nov 6: "too fast and boring"; `SmartCheckRunner.Pacing.show`, 0.35 s per folder, 0.9 s per stage; none with Reduce Motion). The panel is about 420 × 620 pt.

Real data from Evan's Mac (Nov 7), for every sketch:

| Folder | Size | Kind |
|---|---|---|
| Claude app virtual machine | 10.7 GB | refills |
| Cursor snapshots | 9.2 GB | refills |
| App caches | 6.9 GB | refills |
| Python download cache (uv) | 5.3 GB | refills |
| npm cache | 2.8 GB | refills |
| pnpm store | 0.85 GB | refills |
| Codex install leftover | 338 MB | win |
| NVIDIA leftovers | 146 MB | win |

So about 36 GB refills, 484 MB could be cleared (~1.3%). Any honest graphic shows the wins as small.

## What was rejected, and why

1. **SceneKit 3D ring** (Nov 6): "looks like unfinished renderings".
2. **Data globe**, a dot sphere with wedges per folder, 5% minimum width (Nov 6–7): "i hate the globe it makes no sense". Abstract, and the 5% minimum made 1.3% look large. Removed in vitals#15.
3. **Disk bar like macOS Storage settings** (suggested Nov 7): "no i want something more creative".

Current state: five stage rows plus a line on top, "338 MB to clear" over the stage name. Same layout as the finished verdict, so nothing jumps.

## Concepts already sketched (Nov 7, in chat)

Each animates the real data above:
- **Vitals monitor**: an ECG-style sweep; each folder is a beat, height by size, blue for wins. My lead pick: it fits the app's name and the "bedside vitals monitor" direction in `~/Design/audits/2026-11-vitals/README.md`.
- **Receipt**: folders print as line items, caches marked "refills", total = what you could clear.
- **Split-flap board**: rows flip to each folder and size, then the total.
- **Sand jar**: ~100 MB per grain, grey caches, blue wins; the blue layer is honestly thin.

Evan hasn't picked yet. Don't assume one.

## What to research

1. **Creative precedents** for scanning, cleaning and progress moments that carry real data. Look for app UI (Mac, iOS, games, Teenage Engineering, Playdate, Nothing, Panic), data art, motion design, physical instruments (medical monitors, oscilloscopes, flip boards, receipt printers, gauges). For each: what it shows, why it works, link.
2. **More concepts** beyond the four above, at least four new ones. Each must pass these tests:
   - **Makes sense:** a first-time viewer can say what it shows without a caption.
   - **True:** sizes to scale (no minimum widths that lie), caches visibly different from wins, and the end state equals the finished result.
   - **Native:** fits a calm macOS 26 panel (system fonts, SF Symbols, one accent colour, light and dark).
   - **Buildable:** SwiftUI `Canvas`/`TimelineView`, shapes and text. No SceneKit (soft-deprecated at WWDC25), no web views, no 3D engines.
   - **Snapshot-safe:** renders with SwiftUI `ImageRenderer`, which Vitals' `--snapshot` audits use. Native AppKit views like video players don't render there.
   - **Motion:** has a Reduce Motion version and works at the paced 7–9 s.
3. **Score all concepts** (old four plus new) on those tests and on delight. Be blunt about which ones risk "makes no sense".
4. **Sound and haptics:** is there a precedent for a subtle sound or trackpad haptic per found item on macOS? Note it, don't push it.

## Deliverable

`~/Design/research/vitals-scan-graphics.md`:
- A ranked shortlist of 3, each with a one-paragraph pitch and the test scores.
- A table of every concept considered.
- Sources as links.
- For the top pick, the frames that matter: start, mid-scan, end, and how it hands off to the finished verdict screen.

If you can render visuals, sketch the top three animated with the real data above, light and dark.

## Don't

- Don't edit Vitals code or its contract. This is research only.
- Don't propose abstract shapes that only mean "busy" (orbs, particles, spinners, radar sweeps).
- Don't push, deploy, or install anything.
