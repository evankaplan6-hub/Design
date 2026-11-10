Build the menu bar fan for Vitals. The design is finished and tested. Your job is to build it to that design, not to redesign it. If you think a design decision is wrong, tell me before changing it. Where this prompt and the plan differ, this prompt wins.

**What it does.** When the Mac's fan is off, the menu bar shows the normal Vitals pulse. When the fan starts, the pulse morphs into a fan: the zigzag strokes become the blades and the flat tails become the ring. The blades spin in proportion to the real fan speed. When the fan stops, it coasts, waits 8 seconds, and morphs back. No window, sound, notification or focus change, and nothing beside the icon moves.

**Read first**
1. `AGENTS.md` and `CONTRACT.md` in this repo.
2. The full design: `git -C ~/Design show origin/plan/vitals-menu-bar-fan:plans/2026-11-08-vitals-menu-bar-fan.md`. If that branch is gone, the plan has been merged, so use `origin/main` instead.
3. The tested code, for reference only: `git -C ~/Design ls-tree --name-only origin/plan/vitals-menu-bar-fan research/vitals-fan-prototype/`, then read each file with `git show`. Start with `README.md`, `fanprobe.swift`, `realbar2.swift` and `realbar5.swift`. Do not switch branches in `~/Design`.

**Before you edit anything.** I am giving you this now because the Memory tab work is finished and merged. Run `git fetch`, then confirm it: `git grep -q selftest-memorywatch origin/main -- scripts/check.sh` must succeed. Also confirm the checkout is clean, and check open PRs and `~/.codex/worktrees/`, because my rule is one AI per project at a time. If the Memory tab is not on `origin/main`, the checkout has changes, or someone else is still working here, stop and tell me what you found. Never discard, stash or commit someone else's work. Otherwise create `feat/menu-bar-fan` from `origin/main` and build there.

**Hard rules.** Never request notification permission, post a notification, use sudo or cause an admin prompt. The fan is read-only: only read SMC keys, never write one. Do not change my appearance, wallpaper, Reduce Motion or any other setting to run a test, and do not click things on my screen.

**Facts the plan leaves out**
- SMC: open AppleSMC with `IOServiceOpen` and call `IOConnectCallStructMethod` with selector 2. `data8` 9 gets key info and 5 reads. Keys are `FNum` (ui8) and `F0Mn`, `F0Mx`, `F0Ac` (flt). The Swift `KeyInfo` struct needs 3 explicit pad bytes after `attr`. Without them the layout differs from C and every key reads as not present.
- Read the fan count, minimum and maximum from the Mac. Do not hard-code them. Spin is always RPM / 2620. That divisor is a fixed design number.
- Blur during the spin: a sharp copy and a copy smeared 14 degrees cross-fade. The smeared copy's opacity is `min(1, speed / 2.5)`, where speed is turns per second.
- Blur during the morph: smear is `speed * 5.6` degrees, multiplied by smootherstep from t 0.6 to 1.
- Blades are defined in a 20-unit box, scaled by 0.9 points per unit. Hub radius is 1.8 points. Ring radius is 8.1 points. Line width is 1.175 points.
- Outline sampling for the capsule-to-blade morph: 6 points on the cap, 16 on each side, 8 on the tip.
- Draw the morph live, as the tests did. Do not pre-draw it as the plan first said. Each morph frame depends on the live spin and blur, and it only runs for about a second. Spin must stay on Core Animation.
- The icon sits on a fixed-width canvas, 22 points wide, in `statusItem(withLength: 26)`. Pulse, morph and fan all use it. Today the item is variable length and the attention dot adds 3 points. The item may change size once when this installs, but never again after that.
- Ring and hub stay in the status button's template image. Only the blades rotate.
- Use the spin recipe in `realbar5.swift`, not the one in `realbar2.swift`. `realbar2.swift` is right for the morph, but its spin uses hand-colored layers that came out too bright, and the opposite sign. In the template view, a positive angle turns clockwise.

**Fit it to the Vitals code**
- `refreshIcon()` returns early unless the attention state changed, so fan changes need their own path.
- Do not publish fan readings through `VitalsModel`. It would fire `objectWillChange` every second and redraw the panel for nothing. Keep polling on its own timer, off the main thread, with no AppKit in the reader.
- The spinning blade view sits on top of the status button. Make it ignore clicks (`hitTest` returns nil) and hide it from VoiceOver.
- Put the animation in one class that takes a status button and a source of readings, so the app and the test mode below share it.
- Keep new command-line handling in your own file, with one line in `VitalsApp.swift`.
- The tooltip says "Fan 3,400 RPM" only while the fan really reads that. While it coasts or leaves, it says "Fan stopped".

**Testing tools you need to add**
- `--snapshot` draws the panel, not the menu bar icon, so it cannot show the fan. Instead of `--snapshot --simulate-fan`, add `--fan-frames <folder> --simulate-fan <rpm>`, which writes pulse, morph and fan PNGs at true size.
- A second full Vitals cannot run while the installed one does, because it exits at the single-instance check. Add `--fan-bar-test`, placed before that check. It puts a temporary icon in the real menu bar using the shared class, with no notification code, then quits. It needs three modes: a made-up speed timeline, live readings, and Reduce Motion forced on. `CONTRACT.md` says command-line modes show no UI, so record this as the one exception.
- `screencapture -R` failed on this Mac. Capture the full screen and crop.

**Build it in the plan's six steps, in order**
1. Reader, with `--fan-live <seconds>`.
2. `FanIndicator` logic, with `--selftest-fan` added to `scripts/check.sh`.
3. Graphic, with `--fan-frames` and `--fan-bar-test`.
4. Menu bar wiring, including the morph, attention dot, tooltip and VoiceOver label. Add Reduce Motion: pulse cross-fades to a still fan, with no morph, spin or blur.
5. Measure, and run every check below.
6. `CONTRACT.md`: add a fan section and update the "Menu-bar label" line, which says the icon is only an SF Symbol. Then bring the branch up to date with `origin/main`, run `./scripts/check.sh`, open a PR, merge with a merge commit, install, and do `AGENTS.md`'s step 5 checks.

**Stop after step 1 until the fan has really been read spinning.** It has never been read above 0. Tell me you are about to load the Mac, then run `--fan-live` while running one `yes > /dev/null` per core for at most 5 minutes. Make sure every one of them is stopped afterward, even if something fails. If the fan stays at 0, stop and ask me to run something heavy. Do not start the graphics until a real reading above 0 is confirmed.

**These were never tested in the design work. Test each one before merging and report the result.**
- The attention dot over the fan at true size. Check that the dot and ring both stay readable.
- Sharp and blurred blades cross-fading as two template views. The cross-fade was only tested with hand-colored layers, and the template view only with sharp blades.
- Starting the spin with `fromValue` and then changing speed live. Those were tested separately, the first one paused.
- The whole chain in the template view, in both directions, including turning around mid-morph.
- The panel still opens when the fan icon is clicked. Use `performClick` in `--fan-bar-test`, and ask me to click the real icon once after install.
- How the icon looks while the panel is open and the button is highlighted.
- CPU while spinning (target under 1% of one core), and that no neighboring icon moves by even a pixel during the morph.
- A full real cycle before merging, using `--fan-bar-test` on live readings: fan starts, icon appears, speed tracks, fan stops, icon leaves.

**These need me. Ask me at the end, in one list.**
- The color on a light menu bar. Only the dark bar was tested. Ask me to switch to a light wallpaper for a minute.
- Pausing during full screen and display sleep. Build it and test the pause logic in `--selftest-fan`. Report the real behavior as not checked unless I do it.

**Installing.** Follow `AGENTS.md`: after merging, switch to `main`, update it, confirm the checkout is clean and matches `origin/main`, then run `./scripts/build-app.sh`. If the checkout is not clean, stop and tell me. After installing, confirm the Memory tab still works by running `--selftest-memorywatch` and a `--snapshot --tab memory` from the installed app. Then watch one more real fan cycle using the same 5-minute load, and tell me before you start it.

**When you report back,** use short, plain words. Say what changed, what is installed, and what still needs me. Say exactly what you checked. Keep real fan readings apart from simulated ones, and never call a check passed unless you ran it.
