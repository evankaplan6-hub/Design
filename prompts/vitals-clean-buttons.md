Put Smart Check's Clean buttons on screen (Sources/Vitals/Views/SmartCheckCard.swift and a new Views/CleanUpList.swift). The wiring is done on `feat/smart-check-clean-actions`; the look was done in ~/Design. The target is a real SwiftUI file, so port it rather than redraw it.
- The design lives in ~/Design once PR "Vitals Clean buttons" is merged. Until then it is on branch `design/vitals-clean-buttons` (worktree ~/Design-clean-buttons); read it there.
- Read ~/Design/research/vitals-clean-buttons/README.md (the "Final" section) and the blueprint, docs/superpowers/specs/2026-11-14-clean-buttons-blueprint.md.
- Look at final/out/: the result (1b is the same card scrolled to its end), both confirmations, the Clean up screen fresh and mid-session, the result reopened mid-clean, and 7-states (every CleanState). Each is light and dark. Watch motion/out/M2-trash.mp4 for the flight. Where the video and section 6 differ, section 6 wins.
- Code to port: final/CleanButtonsDesign.swift. Its CleanRow, CleanIcon, CleanUpScreen and ResultScreen's `entry` are the layout, sizes and words to match. It already compiles against this repo's own files (final/render.sh), so the types and calls are real.
- Read CONTRACT.md first. Its honesty, privacy and look rules, and the blueprint's eight rules, win over the design file.
- Use the app's own pieces: Module, glassButton, StatusGlyph, Spinner, CopyForClaudeButton(iconOnly: true), IconCache, ScrollIfLive, SectionHeading-style headings and Theme.secondaryText. The design file fakes the panel chrome, the stage figures, the NSAlert and "Rebuilds itself 35.7 GB", and leaves out the tally squares.
- Don't edit the wiring (CleanEngine.swift, CleanController.swift except DEBUG-only preview data, the SystemActions clean section, CleanSelfTest.swift). New words go in a new file, SmartCheck/CleanWords+Design.swift, as an `extension CleanWords` (move it over as it is from the top of CleanButtonsDesign.swift). Ask the wiring session for anything else.

What to build, top to bottom:
1. The result card.
   - A "Clean up" row right after "Also needs a look" and its divider, before "Biggest wins". Only when `cleanablePlans(in:)` is not empty.
     - Callout "Clean up" on the left. On the right, "7 items" in Theme.secondaryText, then a chevron.
     - While a clean runs, the right side says "Cleaning npm cache" with a Spinner instead of the count; during a Put Back, "Putting back Cursor snapshots". Reopening the panel mid-clean shows it. Take the words from the busy row's state (ResultScreen.entryValue).
     - About 40 pt tall, radius 12, `.fill.tertiary` on the module. A real Button; VoiceOver reads "Clean up, 7 items" (label "Clean up", value the count or the busy words; chevron and spinner hidden).
   - Biggest wins rows become CleanRows: the icon, title, caption, the finding's action and Copy for Claude. Same rows, same order, same "+N more". A win with no plan (Hugging Face, Ollama, simulators, device support: `notOffered`) keeps today's caption "up to X · note" with no action, only the icon added. This changes the decided "Biggest wins stays as it is"; Evan approved it in the B3 pictures on Nov 14.
   - The header's second line adds measured totals: "Checked at 9:49 AM · Freed 120 MB · 146 MB in the Trash". Leave out a part that is 0. Never a junk total, never the "up to" figures. Add the totals to the header's VoiceOver label too.
   - Freed is `cleaner.totalFreed`. In the Trash is the sum of `outcome.movedToTrashBytes` over rows whose state is `.done(_, _, canPutBack: true)`, not `cleaner.totalMovedToTrash`, which never drops when the Trash is emptied (Scan.totals in the design file).
   - Nothing else on the card changes. The tally squares stay where they are.
2. The Clean up screen, one level down, inside the same Smart Check module (it replaces the scroll area; Check again and Done hide while it shows).
   - Top bar: a round glass Back button (chevron.left, label "Back") on the left, "Clean up" in .headline centred (header trait), then a divider. Escape still closes the panel, as today.
   - VoiceOver focus moves to the "Clean up" title when the screen opens, and back to the Clean up row on Back, with the card's existing @AccessibilityFocusState pattern.
   - "One at a time. Wait for npm cache to finish." in .footnote while `cleaner.busy`, naming the row that is cleaning or putting back.
   - Two groups from `cleanablePlans(in:)`, each still biggest first:
     - "Stays free" for `!plan.comesBack`, with "up to 486 MB" on the right: the sum of `expectedBytes` over its rows that are not done, putting back or put-back-failed. Hide the figure at 0.
     - "Comes back as you work" for `plan.comesBack`, with no figure (no total of caches that refill).
     - Headings: callout semibold, Theme.secondaryText, 24 pt, header trait.
   - The list scrolls: copy the card's own ScrollIfLive modifiers (.scrollIndicatorsFlash, minHeight 0, clipped). Never put .fixedSize on the ScrollIfLive itself; the design file puts it on the content inside, for the snapshot. Below it, pinned, a divider and the totals line in callout Theme.secondaryText: "Freed 120 MB · 146 MB in the Trash", only once something is measured.
   - The screen stays until Back, a new scan or the panel closing. Done rows stay in the list until the next scan.
3. One row (CleanRow), for both places.
   - Icon 28 pt: the first blocker's app icon (`NSWorkspace.urlForApplication(withBundleIdentifier:)` then IconCache), else the generic folder icon. Never read inside the folder for it.
   - Title callout, up to 2 lines. Caption .caption, up to 4 lines, wrapping, never "…".
   - The action sits in a 124 pt column, trailing, so captions wrap the same in every state. Then Copy for Claude, always.
   - Row at least 44 pt tall.
4. The states (draw each as 7-states shows):
   - ready: caption "up to 10.2 GB · Old package downloads" (the size, then the note's first clause, like SmartWinRow). Button `plan.buttonTitle` ("Clean" or "Move to Trash"), glass.
   - blocked and waiting buttons are disabled, so SystemActions.clean's "Quit X first" and "Another clean is still running" alerts no longer show. The caption carries the first; the "One at a time" line carries the second.
   - blocked: the button disabled; the caption swaps the note for `CleanError.blocked(apps:).message`: "up to 10.8 GB · Quit Cursor first, then try again." It clears by itself when the app quits.
   - waiting: the button disabled, caption unchanged.
   - cleaning: a Spinner in the action column. Caption "Cleaning. This can take a few minutes." for a tool, "Moving to the Trash" for the Trash. Spinner label "Cleaning npm cache".
   - done: `outcome.message` in .primary (it is the news; never green). "Put Back" while `canPutBack`, labelled "Put back Cursor snapshots", disabled while `cleaner.busy` (the controller ignores it then). No button otherwise.
   - puttingBack: the message stays, a Spinner in the action column, labelled "Putting back Cursor snapshots".
   - putBack: never returned by `state(for:)` (the row is offered again); it looks like ready.
   - putBackFailed: a 10 pt StatusGlyph(.warning) and `message` in .primary, and Put Back again (disabled while busy).
   - failed: the same glyph and message, and `plan.buttonTitle` again (pressing retries).
   - notOffered: no row in Clean up (`cleanablePlans` leaves it out). In Biggest wins it keeps "up to X · note" and no action.
5. The confirmation stays SystemActions.clean's NSAlert (.warning style): the plan's confirmTitle, confirmMessage and confirmButton first, then Cancel, the default (Return). The panel closes only on its icon or Escape, so an in-panel sheet would fight Escape. Don't add a second confirmation.
6. Motion (M2), critically damped springs only (bounce 0):
   - Pressing a button (after the alert): it cross-fades to the Spinner in the same column (response 0.3). The result fades in (0.35). Figures appear whole: no counting up.
   - A Trash clean: the row's icon flies on a short arc (0.45 s) to a small trash glyph beside the totals line, leaving a 1 pt dashed rounded slot. The glyph shows only while `totalMovedToTrash > 0` and pulses once (scale 1.14) when the icon lands. Put Back flies it back the same way.
   - The "Stays free" figure changes when the icon lands, not before.
   - From a Biggest wins row on the result card there is no totals line to fly to: the icon cross-fades to the dashed slot and the header totals fade in.
   - Reduce Motion: no flight and no scaling. The icon cross-fades to the slot, and words cross-fade.
7. Words. Add these to CleanWords; the views never spell a sentence (final/CleanButtonsDesign.swift has them as an extension, ready to move):
   - "up to X" and the " · " caption joiner (CleanPolicy's own size words are private).
   - "Clean up", "7 items" / "1 item", "Stays free", "Comes back as you work", "Put Back", "Back".
   - "Cleaning. This can take a few minutes.", "Moving to the Trash".
   - "Cleaning X", "Putting back X", "Put back X" (the same words SystemActions already speaks).
   - "One at a time. Wait for X to finish."
   - Totals: "Freed X", "X in the Trash", joined with " · ".
   - Everything else is already in CleanPolicy, CleanWords and CleanError: button titles, confirmations, outcome sentences, the blocked sentence and failure messages. Use them as they are.

Raise with the wiring session, not in the view:
- The NVIDIA confirmation reads "Move Possible leftovers from NVIDIA to the Trash?": the title's capital P lands mid-sentence.
- After the Trash is emptied, the outcome still says "Empty the Trash to get the space back." The row needs a sentence for that case (`canPutBack` false on a Trash outcome).
- `totalMovedToTrash` never drops when the Trash is emptied. Until the wiring fixes it, the view sums the rows (section 1).
- Put Back pressed while busy is silently ignored. The view disables it; `state(for:)` could report that instead.
- "Rebuilds itself 35.7 GB" counts app caches, logs and the Claude VM, so it won't match the cache rows. That is today's rule; leave it unless Evan says otherwise.

Testing and contract:
- Add #Previews for every `CleanPreviewStates.all` entry in Views/Previews.swift, plus the Clean up screen fresh and mid-session.
- Add `--simulate-clean fresh|session|reopened` to --snapshot and --live-snapshot, using preview data only (feed the views states directly, or add DEBUG-only preview data to CleanController). It must never run a clean.
- Update CONTRACT.md: the Smart Check section (the Clean up row, the screen, the states, the totals, the motion and Reduce Motion), and that the words live in CleanWords.
- Work on a branch from `feat/smart-check-clean-actions`, run ./scripts/check.sh (it includes --selftest-clean) and open a PR.
- Nothing may appear on Evan's screen. Judge the look from `--snapshot <out.png> --tab check --appearance light|dark` with each simulated state, and the layout from `--live-snapshot <out.png> --offscreen --tab check` (its buttons always draw greyed). Never `--running-app`. Put the pictures next to final/out/ and say which are the real window.
- Check VoiceOver labels from --live-snapshot: every action is a real button named by its title, Put Back has its own label, the headings are headers, the header includes the totals, and focus moves on opening Clean up and on Back.
- Check that the result card's last row ("Rebuilds itself", the tally) is reachable by scrolling, and that nothing is cut by "…" (a row cut at the scroll edge is fine).
- Never press a real Clean button. It deletes Evan's real caches.
- Don't merge or install until I say mnd.
