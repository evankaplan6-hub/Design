# Vitals Smart Check: Clean buttons (Nov 14)

Evan: "when i run a vitals check why cant i actually do the things it says to do like how cleanmymac worked?"
The wiring is done on `feat/smart-check-clean-actions` in `~/claude/vitals`. This folder is the look.

## Directions (`directions/out/`, real SwiftUI drawn offscreen, not the app)
Sizes are the Nov 14 scan's real ones. Outcomes are made up, including the disappointing uv one.
Glass, spinners, the segmented control and NSAlert are flat stand-ins: ImageRenderer can't draw them.

- **A, under the verdict.** The first three rows sit on the result card above the stage rows, "+4 more" for the rest. The confirmation opens inside the row.
- **B, its own screen.** One "Clean up" row on the result opens a second screen with all seven rows, a running total and Done. The confirmation is a sheet inside the panel.
- **C, at the end of the result.** All seven rows in a dense list after "Biggest wins". The confirmation is an NSAlert.

Pictures: `A-1-session`, `A-2-confirm`, `B-1-entry`, `B-2-session`, `B-3-confirm`, `C-1-session`, `C-2-confirm`, each light and dark.

## B2, after reading the CleanMyMac design system (Nov 14)
Evan's CleanMyMac design system (claude.ai artifact, measured from the main window, not its menu-bar mini app) backs B: "Totals, not lists", with the list one level down in a Manager screen reached by Review, with Back and Done.
B2 takes what fits Vitals' rules: a real app or folder icon per row (Cursor, ChatGPT, Xcode; a folder for the rest), Back with a centred title, and a footer with the running total and Done (`B2-session`, `B2-confirm`).
Left out on purpose: pre-ticked checkboxes with one Run for everything (no "Clean all"), a "5.2 GB of junk" total (no junk total), colour-coded canvases, magenta and glossy renders (colour means status only), and its "Looking for junk…" voice (no ellipses).

## Blind read (three reviewers, not told which was preferred)
A CleanMyMac user, a macOS designer and an honesty reviewer. Rankings: **B, A, C**; B, A, C; B, C, A.
- B: every state is visible together, the total and Put Back stay in view, and the sheet stops a second press.
- A: "+4 more" hides the Trash row and its Put Back. The inline confirm pushes rows under the pointer and leaves other buttons live.
- C: Codex and NVIDIA show twice with different states, and the result gets long.

Fixed after the read, in all three: waiting rows keep their words (only the button dims), a blocked row keeps its size, every row keeps its finding's note ("Possible: the app seems to be gone"), the totals line says what is in the Trash, B got Done, and C lost a leftover annotation.

## Open points (raise with Evan). Superseded: B3 and the Final section below settle these.
- **New words.** "Freed 120 MB. The rest is still in use." is a proposed `CleanWords` sentence for a prune that frees far less than "up to". "Clean up", "Cleaning" and "146 MB in the Trash" also need to come from `CleanWords`, not the view.
- **Two numbers disagree.** The Storage stage says "Up to 486 MB you could clear" (lasting wins only) while the list shows 10.8 GB and 10.2 GB caches. That is today's rule, but it now sits beside the buttons.
- **Biggest wins after a clean.** Codex and NVIDIA are both wins and cleanable. After a clean the win row still says "up to".
- Cancel is the blue default, as NSAlert draws it. One reviewer would rather Clean sit on the right without blue fill.

## Motion (Nov 14, after Evan asked for "cool graphics and animations")
Three studies on B2, drawn frame by frame with real SwiftUI offscreen (`motion/Motion.swift`, videos in `motion/out/`). Same story in each: uv is cleaned and frees 120 MB of "up to 10.2 GB", NVIDIA goes to the Trash, then Put Back. The confirmation sheet is cut from the videos. Springs are critically damped (no bounce).
- **M1, morph.** The button shrinks into a turning ring while it works (the tools report no progress, so the ring never pretends to fill), then the result slides in.
- **M2, into the Trash (chosen by the blind read, 2 of 3 first).** M1, plus the item's icon flies on a short arc into a Trash glyph beside "146 MB in the Trash" and leaves a dashed empty slot in its row. Put Back flies it back along the same path. The glyph shows only while something is in the Trash.
- **M3, squares.** Dropped. A 120 MB clean changes one square in about 270, and the honesty reviewer showed that freed and in-the-Trash squares looked alike and part squares were rounded up.

Fixed during the read: figures no longer count up (that showed numbers that were never measured, such as "140 MB in the Trash"); they fade in whole. Titles and captions wrap instead of ending in "…". A "Freed 120 MB" figure flying to the footer was tried and cut: it crossed other rows' text.
Reduce Motion: no flight, no ring shrink; the row icon cross-fades to the dashed slot and the words cross-fade.
New words to add to `CleanWords`: "Cleaning", "Moving to the Trash".

## B3, after Evan's "critique what you're proposing" (Nov 14)
The critique's top four, fixed (`directions/out/B3-*`, `directions/b3-strip.png`):
1. **A way to clean from the result.** A "Clean up · 7 items ›" row sits first under the stages, and the Biggest wins rows get their own buttons and icons.
2. **NSAlert, not a sheet.** The panel closes only on its icon or Escape, so a sheet inside it would fight Escape. Cancel is the default (`B3-2-confirm`, `B3-2b-confirm-clean`).
3. **Long cleans and coming back.** A cleaning row says "Cleaning. This can take a few minutes." Reopening mid-clean shows "Cleaning npm cache" on the Clean up row (`B3-5-reopened`). Other buttons dim with "One at a time. npm cache is cleaning."
4. **Two groups.** "Stays free" (Codex, NVIDIA: lasting, up to 486 MB) above "Comes back as you work" (caches). This explains why Storage says 486 MB while Cursor shows 10.8 GB. One Back, no Done. The list scrolls and the totals line stays pinned.

## Once-over (three new reviewers, before the last fixes all said "not ready")
Fixed: "Stays free" recounts from rows still offered (340 MB once NVIDIA is in the Trash), in the pictures and the M2 video. Long captions wrap to four lines instead of being cut. The totals line no longer scrolls away. Rows no longer squash when the list is long. "Nothing in the Trash" removed (the Trash may hold other things). The uv outcome uses the exact `CleanWords` sentence "Freed 120 MB."

## For Evan to decide (not the design's to fix)
- **Grouping changes a decision.** "One list, biggest first" becomes two groups, each biggest first.
- **"Rebuilds itself 35.7 GB"** is the card's existing figure and includes app caches, logs and the Claude VM, so it does not match the 25.4 GB of cache rows.
- **Words to add to `CleanWords`:** "Clean up", "7 items", "Stays free", "Comes back as you work", "Cleaning. This can take a few minutes.", "Moving to the Trash", "One at a time. X is cleaning.", "Cleaning X".
- **Wiring:** the NVIDIA confirm title reads "Move Possible leftovers from NVIDIA to the Trash?" (capital P mid-sentence).
- Storage and Apps stage rows keep the scan's figures after a clean until Check again.
- Ideas not drawn: a "Show Trash" link, words for the Put Back state, a tooltip on Copy for Claude.

Checked: offscreen SwiftUI renders and the motion frames only. Not checked in the real app.

## Final (Nov 14, after Evan's "Yes, build it")
`final/CleanButtonsDesign.swift`, drawn by `final/render.sh` into `final/out/` (light and dark).
The script compiles the design file together with Vitals' own files at commit a489c94 (read with `git show`, nothing checked out), so the states come from `CleanPreviewStates.all` and the plans, sizes and sentences from `CleanPolicy`, `CleanWords`, `CleanError` and `SmartSizer`. Module, glassButton, StatusGlyph, Spinner, SnapshotCircleButton and IconCache are the app's own, drawn in their snapshot forms (so a spinner is an hourglass).
Faked: the panel's title bar and tabs, the stage figures, "Checked at 9:49 AM", "Rebuilds itself 35.7 GB" and the NSAlert. The tally squares are left out of these pictures; they stay where they are.

- `1-result`: the Clean up row and Biggest wins with their buttons. `1b-result-scrolled`: the same card to its end.
- `2-confirm-clean`, `3-confirm-trash`: the NSAlert with the plan's own words, Cancel the default.
- `4-cleanup`, `5-cleanup-session`: the Clean up screen, fresh and mid-session (Cursor open, pnpm freed 120 MB, NVIDIA in the Trash, npm cleaning).
- `6-result-reopened`: the result reopened mid-clean, with the totals in the header.
- `7-states`: every CleanState.

The new words sit in an `extension CleanWords` at the top of the file, ready to move into the app.

Answers to the brief's open questions:
- Where the list sits: one "Clean up" row on the result opens its own screen (Back, two groups, pinned totals). Biggest wins rows also get their buttons.
- Confirmation: SystemActions.clean's NSAlert, Cancel the default. An in-panel sheet would fight Escape, which closes the panel.
- Put Back: shown while `canPutBack` (until the Trash is emptied) or the next scan, and disabled while another clean runs.
- The verdict header shows measured totals ("Freed 120 MB · 146 MB in the Trash"), never "up to".
- The disappointing case: the row says the exact outcome ("Freed 120 MB.") and the "up to" figure is gone, with no apology or colour.
Build prompt: `prompts/vitals-clean-buttons.md`.
New for the wiring session: after the Trash is emptied, the outcome still says "Empty the Trash to get the space back."

### Review of the final (three reviewers, each finding checked by a second agent)
Confirmed and fixed: Put Back now dims while another clean runs (the controller ignores it then). The Trash total is summed from rows still in the Trash, because `totalMovedToTrash` never drops when the Trash is emptied. The Clean up row says "Putting back X" during a Put Back. A Biggest wins row with no button keeps its "up to" caption. The alert draws its buttons in NSAlert's order (confirm, then Cancel as the blue default) with the warning badge. `.fixedSize` moved inside the scroll content so the live list still scrolls. The prompt now covers VoiceOver focus, header totals, where the new words live, "Back", and where to read the design before this PR merges.
Thrown out on checking: words can't go in CleanWords (an extension in its own file works), `--simulate-clean` needs the wiring changed (states can be fed directly), and the video contradicts the written motion.
