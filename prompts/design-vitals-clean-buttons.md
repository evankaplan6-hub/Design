# Design: Clean buttons for Vitals' Smart Check

You're picking up a design task for **Vitals**, Evan's native macOS menu-bar app (`~/claude/vitals`, SwiftUI, macOS 26+). Read `~/claude/vitals/CONTRACT.md` and `~/Design/ETHOS.md` first. Evan is non-technical; write plainly.

## The ask

Evan, Nov 14: "when i run a vitals check why cant i actually do the things it says to do like how cleanmymac worked?" Smart Check now has the wiring to act on what it finds: a Clean or Move to Trash button per finding, a confirmation, Put Back, and running totals. **None of it is on screen yet.** Your job is the look: where the buttons sit, how each state looks, and the confirmation. The wiring is done and tested; don't change it.

## Read first

1. The blueprint. It is the brief: the API, all ten states, the eight rules, open questions and the real scan.
   `git -C ~/claude/vitals show origin/feat/smart-check-clean-actions:docs/superpowers/specs/2026-11-14-clean-buttons-blueprint.md`
   If that branch is gone, it has been merged: use `origin/main`.
2. The states with real sizes, for previews: `CleanPreviewStates` at the bottom of `Sources/Vitals/SmartCheck/CleanController.swift` (same branch, read it with `git show`).
3. Today's card: `Sources/Vitals/Views/SmartCheckCard.swift` on `origin/main`.
4. The live list of buttons on Evan's Mac (a dry run; it never cleans): `~/claude/vitals/.build/release/Vitals --clean-plan` if built, otherwise use the table in the blueprint.

Do not switch branches or edit files in `~/claude/vitals`. Work only in `~/Design`, on your own branch.

## What's decided (don't reopen without telling Evan first)

- Buttons get their own list, biggest first, one row per cleanable finding. "Biggest wins" stays as it is.
- Always a confirmation, Cancel as the default.
- No "Clean all" and no big "junk" total.
- Before a clean, sizes say "up to". After, only measured figures.
- Colour means status only. A finished clean is not a green celebration.

## What's yours to decide

- Where the list sits on the card and how it opens (always shown, "+N more", or a second screen).
- How ready, blocked ("Quit Cursor first"), waiting, cleaning (up to 3 minutes), done, failed and Put Back look.
- NSAlert or an in-panel confirmation.
- How long Put Back stays, and whether the verdict header shows "Freed 8.3 GB".
- Design for the disappointing case too: `uv cache prune` can free 120 MB of an "up to 10.2 GB".

## How to work

1. Ask Evan one plain question if something truly blocks you. Otherwise start.
2. Show 2 or 3 directions as pictures before writing any spec. Use the real sizes. Say your doubts about each one unasked.
3. After Evan picks, build the final in SwiftUI like `research/vitals-battery-redesign/swiftui/BatteryDesign.swift`: one file that draws every state from `CleanPreviewStates`, rendered light and dark. Use the app's own pieces where you can and say where you faked them.
4. Put everything in `research/vitals-clean-buttons/` with a `README.md`.
5. Finish with a build prompt, `prompts/vitals-clean-buttons.md`, in the style of `prompts/vitals-battery-tab.md`, for a Vitals session to port it. It must list the states, the words (taken from `CleanPolicy` and `CleanWords`, never new ones in the view), and the checks.

## Hard rules

- Nothing on Evan's screen. Assume he is clicking and typing in other apps. No windows, no bringing apps to the front, no opening his Vitals panel, no `--running-app`. Render offscreen.
- Never press a real Clean button or run a clean. It deletes Evan's real caches.
- Commit to a branch and open a PR in `~/Design`. Check `git status` first and never touch other work there.
