Build the menu bar fan for Vitals. The design is finished and tested. Your job is to build it to that design, not to redesign it. If you think a design decision is wrong, tell me before changing it.

**What it does.** When the Mac's fan is off, the menu bar shows the normal Vitals pulse. When the fan starts, the pulse morphs into a fan: the zigzag strokes become the blades and the flat tails become the ring. The blades spin in proportion to the real fan speed. When the fan stops, it coasts, waits 8 seconds, and morphs back. No window, sound, notification or focus change, and nothing beside the icon moves.

**Read first**
1. `AGENTS.md`, `CLAUDE.md` and `CONTRACT.md` in this repo.
2. The full design: `git -C ~/Design show origin/plan/vitals-menu-bar-fan:plans/2026-11-08-vitals-menu-bar-fan.md`. If that branch is gone, the plan has been merged, so use `origin/main` instead.
3. The tested code, for reference only: `git -C ~/Design ls-tree --name-only origin/plan/vitals-menu-bar-fan research/vitals-fan-prototype/`, then read each file with `git show`. Start with `README.md`, `fanprobe.swift`, `realbar2.swift` and `realbar5.swift`. Do not switch branches in `~/Design`.

**Protect other work.** Another session has been working in this repo. When this prompt was written, the main checkout was on `feat/memory-tab` with unsaved edits, and PR 20 was open. Check `git status`, open PRs and `~/.codex/worktrees/` first. Never discard, stash or commit that work. Build in a new worktree on a new branch from `origin/main`. Never request notification permission, post a notification, use sudo or cause an admin prompt. The fan is read-only: only read SMC keys, never write one.

**Facts the plan leaves out**
- SMC: open AppleSMC with `IOServiceOpen` and call `IOConnectCallStructMethod` with selector 2. `data8` 9 gets key info and 5 reads. Keys are `FNum` (ui8) and `F0Mn`, `F0Mx`, `F0Ac` (flt). The Swift `KeyInfo` struct needs 3 explicit pad bytes after `attr`. Without them the layout differs from C and every key reads as not present.
- This Mac has 1 fan, 2,317 minimum and 6,550 maximum RPM. Do not hard-code those. Read them.
- Blade blur: the blurred copy's opacity is `min(1, speed / 2.5)`, where speed is turns per second. Maximum smear is 14 degrees.
- Blades are defined in a 20-unit box, scaled by 0.9 points per unit. Hub radius is 1.8 points. Ring radius is 8.1 points. Line width is 1.175 points.
- Outline sampling for the capsule-to-blade morph: 6 points on the cap, 16 on each side, 8 on the tip. See `realbar2.swift`.
- The icon sits on a fixed-width canvas, 22 points wide. The test used `statusItem(withLength: 26)`. Pulse, morph and fan must all use the same width. The status item today is variable length, so this needs care: confirm that the plain pulse does not shift when the fixed width goes in, and tell me if it does.
- Ring and hub stay in the status button's template image, with no blades drawn in it. Only the blades rotate.
- The status button is flipped, so a positive angle turns clockwise.

**Build it in the plan's six steps, in order**
1. Reader, with `--fan-live <seconds>`.
2. `FanIndicator` logic, with `--selftest-fan` added to `scripts/check.sh`.
3. Graphic, with `--simulate-fan <rpm>` for `--snapshot`.
4. Menu bar wiring, including the morph, attention dot, tooltip ("Fan 3,400 RPM") and VoiceOver label. Add Reduce Motion: pulse cross-fades to a still fan, with no morph, spin or blur.
5. Measure.
6. `CONTRACT.md` section, `./scripts/check.sh`, PR, merge commit, install.

**Stop after step 1 until the fan has really been read spinning.** It has never been read above 0. Tell me you are about to load the Mac, then run `--fan-live` while running one `yes > /dev/null` per core for at most 5 minutes. Make sure every one of them is stopped afterward, even if something fails. If the fan stays at 0, stop and ask me to run something heavy. Do not start the graphics until a real reading above 0 is confirmed.

**These were not tested in the design work. Test each one and report the result.**
- The icon's color when the menu bar turns light. Only the dark bar was tested. Check both.
- Sharp and blurred blades cross-fading together as two template image views. Each was tested only separately.
- Pre-drawn morph frames. The tests drew frames live, and the plan says pre-draw them. Confirm the pre-drawn morph is just as smooth, and turns around cleanly mid-morph.
- CPU while spinning (target under 1% of one core) and while hidden or asleep, in the real build.
- That no neighboring menu bar icon moves by even a pixel during the morph.
- A full real cycle: fan starts, icon appears, speed tracks, fan stops, icon leaves.

**Installing.** `AGENTS.md` requires a clean checkout that matches `origin/main`. The main checkout may not be clean, so after merging, install by running `./scripts/build-app.sh` from a clean worktree at `origin/main`. First check whether `feat/memory-tab` has merged. If it has not, and the installed app includes that work, installing from main would remove it from my running app. In that case stop and ask me.

**When you report back,** use short, plain words. Say what changed, what is installed, and what still needs me. Say exactly what you checked. Keep real fan readings apart from simulated ones, and never call a check passed unless you ran it.
