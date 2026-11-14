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

## Open points (raise with Evan)
- **New words.** "Freed 120 MB. The rest is still in use." is a proposed `CleanWords` sentence for a prune that frees far less than "up to". "Clean up", "Cleaning" and "146 MB in the Trash" also need to come from `CleanWords`, not the view.
- **Two numbers disagree.** The Storage stage says "Up to 486 MB you could clear" (lasting wins only) while the list shows 10.8 GB and 10.2 GB caches. That is today's rule, but it now sits beside the buttons.
- **Biggest wins after a clean.** Codex and NVIDIA are both wins and cleanable. After a clean the win row still says "up to".
- Cancel is the blue default, as NSAlert draws it. One reviewer would rather Clean sit on the right without blue fill.
