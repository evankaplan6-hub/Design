# Menu bar fan for Vitals: design plan

**Request (2026-11-08):** a fan graphic in the Mac menu bar that is real and responsive. It is not there when the fan is off. When the fan runs, it appears without interrupting anything and animates to show how fast the fan is spinning.

**Status:** plan only. Nothing is built.

## What was checked on this Mac

Read-only test on the MacBook Pro (Apple M5, Mac17,2), macOS 27.2, no admin rights.

| Fact | Result |
|---|---|
| Fans | 1 |
| Live speed right now | 0 RPM (stopped) |
| Lowest running speed | 2,317 RPM |
| Highest speed | 6,550 RPM |
| Cost of one reading | Under 2 ms |

**Not checked yet:** a reading with the fan actually spinning. It was off during the test. Build step 1 closes this gap before any graphics work.

## Where it lives

Inside Vitals (`~/claude/vitals`). It is already running in the menu bar and already follows the rules this needs: real numbers, no admin prompts, plain words. It has no fan code today.

| Option | Trade-off | Verdict |
|---|---|---|
| **Fan grows out beside the Vitals pulse icon, in the same menu bar item** | Only icons to its left move, about 22 points. Clicking it opens the Vitals panel. | **Recommended** |
| A separate menu bar item | Can be dragged anywhere, but a new item can land at the far left and get hidden by the notch. | No |
| Pulse icon turns into the fan | Nothing moves at all, but it does not "pop up" and the pulse disappears. | No |
| A new standalone app | Duplicates what Vitals already does. | No |

## How it behaves

**Fan off:** nothing is drawn and no space is used. Vitals checks the fan every 2 seconds.

**Fan starts:** on the first reading above 0, a 22-point slot opens beside the pulse in 0.28 seconds and the fan scales up and fades in with no bounce. It leaves the same way. No window, banner, sound or focus change. Checks speed up to once a second while it runs.

**Fan running:** the icon's spin follows the real speed. Changes are smoothed over about a second so it speeds up and slows down like something with weight.

**Fan stops:** the icon coasts to a stop and stays 8 seconds, then shrinks away. The wait stops it flickering if the fan pulses on and off.

**Hover:** the tooltip says "Fan 3,400 RPM". VoiceOver reads the same. There is no number in the bar.

## How speed maps to spin

The real fan turns 39 to 109 times a second. No screen can show that, and at those speeds the blades would appear to wobble or run backward.

So the icon turns at exactly 1/2,620 of the real speed:

| Real fan | Icon |
|---|---|
| 2,317 RPM | 0.9 turns a second |
| 4,000 RPM | 1.5 turns a second |
| 6,550 RPM | 2.5 turns a second |

Twice the real speed is twice the icon speed, so the animation stays true. 2.5 turns a second also stays under the point where a 5-blade icon at 30 frames a second starts to look like it runs backward.

The blades also blur as speed rises, up to about 30 degrees of smear at full speed. Each frame is several copies of the blades added together, like a camera shutter. Sharp when slow, a soft blur when fast.

## The drawing

- A round ring that stays still, with five blades spinning inside it around a separate hub, 18 points.
- What keeps it from looking like a flower: blade tips cut square along a circle, a visible gap between blades and hub, and the fixed ring.
- Six ideas were rendered at the real 36-pixel size beside the actual menu bar icons (`research/vitals-fan-icon-study.png`). Apple's own SF Symbols fan reads as a clover. The snail-shaped blower case turns to mush. The solid square is too heavy. A bare pinwheel looks like a toy. A reviewer who was not told the subject picked the ring and named it a fan or turbine. The outline square came second and is the backup.
- Numbers, in a 20-unit box centered on the hub, angles clockwise from the top. Each blade starts at radius 2.9, angle 0. It curves to radius 7.3, angle 38, with its control at radius 5.1, angle 5. It follows the circle to angle 68, then curves back to radius 2.9, angle 18, with its control at radius 5.1, angle 29. Hub radius 2. Ring radius 9, line width 1.3.
- Drawn in code next to the existing `MenuBarIcon` in `VitalsApp.swift`.
- Black-and-clear "template" images, so macOS colors it correctly on any wallpaper and in light or dark.
- The pulse and its needs-attention state stay exactly as they are.

## Staying light

The icon must not cause the heat it reports.

- Blades repeat every 72 degrees, so 18 pre-drawn frames at each of 4 blur levels cover the whole spin. Built once, then swapped.
- 30 frames a second at most. 15 in Low Power Mode.
- Pauses when the display sleeps or the menu bar is hidden in full screen.
- Target: under 1% of one CPU core while spinning, measured. If image swapping misses that, switch the blades to a Core Animation layer that runs outside the app.
- With Reduce Motion on, the fan appears and holds still, with no spin and no blur. The tooltip still gives the speed.

## Build steps

Work on a branch from `origin/main`. Another Claude session currently has Vitals on `feat/memory-tab`, and PR 20 is open, so check `git status` and open PRs first and use a separate worktree.

1. **Reader.** New `Sources/Vitals/FanReader.swift`, read-only. Reads the fan count, minimum, maximum and live speed from AppleSMC. It keeps one connection open. If the keys are missing, it reports "no fan" and the icon never appears. Add `--fan-live <seconds>`. Then Evan runs a few minutes of heavy work so the live speed can be confirmed above 0.
2. **Behavior.** New `FanIndicator` logic with no drawing in it: show, smooth, coast, hide. Add `--selftest-fan` with made-up timelines (off, start, flicker, full speed, missing sensor) and add it to `scripts/check.sh`.
3. **Graphic.** Draw the frames. Add `--simulate-fan <rpm>` to `--snapshot`. Check it on light and dark wallpapers.
4. **Menu bar.** Wire it into `StatusItemController.refreshIcon`, including the slot animation, tooltip and VoiceOver label.
5. **Measure.** CPU while spinning, CPU while hidden, and icons not jumping or hiding behind the notch.
6. **Ship.** Add a section to `CONTRACT.md`, run `./scripts/check.sh`, open a PR, merge, install with `./scripts/build-app.sh`, then watch a real fan cycle: appears, tracks, leaves.

## Not included

- Controlling the fan. Vitals only reads it.
- A speed number in the menu bar.
- Fan history or a new panel tab.
- Notifications about the fan.

## Calls made for Evan to check

- Lives in Vitals, beside the pulse icon.
- 8 seconds before it leaves.
- White like the other menu bar icons, no color for high speed.
