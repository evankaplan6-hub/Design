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
| **The Vitals pulse morphs into the fan, then back (Evan's idea)** | No other icon moves at all. Clicking it still opens the Vitals panel. | **Chosen** |
| Fan grows out beside the pulse | Icons to its left move about 22 points each time. | No |
| A separate menu bar item | Can be dragged anywhere, but a new item can land at the far left and get hidden by the notch. | No |
| A new standalone app | Duplicates what Vitals already does. | No |

## How it behaves

**Fan off:** the normal Vitals pulse. Vitals checks the fan every 2 seconds.

**Fan starts:** on the first reading above 0, the pulse morphs into the fan in about a second. Nothing appears from nowhere: the five zigzag strokes of the pulse swing out and thicken into the five blades, the two flat tails sweep around into the ring, and the hub grows from the point where the long stroke was cut. No window, banner, sound or focus change. Checks speed up to once a second while it runs.

**Fan running:** the icon's spin follows the real speed. Changes use a no-bounce spring with a 1.1 second response, so speed never changes abruptly and the fan feels like it has weight.

**Fan stops:** the blades coast to a stop and the fan stays 8 seconds, then the same morph plays in reverse. The wait stops it flickering if the fan pulses on and off. If the fan restarts mid-morph, the shape turns around from where it is, with no jump.

**Needs attention:** the small dot stays in its usual corner over the fan.

**Icon width:** the pulse, the fan and every morph frame are drawn on one fixed-width canvas, so nothing beside it ever shifts.

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

The blades also blur as speed rises, up to 14 degrees of smear at full speed. A real menu bar test at 30 degrees turned the blades into a gray disc, so the blades must stay visible. Each frame is several copies of the blades added together, like a camera shutter. Sharp when slow, a soft blur when fast.

## The drawing

- A round ring that stays still, with five blades spinning inside it around a separate hub, 18 points.
- What keeps it from looking like a flower: blade tips cut square along a circle, a visible gap between blades and hub, and the fixed ring.
- Six ideas were rendered at the real 36-pixel size beside the actual menu bar icons (`research/vitals-fan-icon-study.png`). Apple's own SF Symbols fan reads as a clover. The snail-shaped blower case turns to mush. The solid square is too heavy. A bare pinwheel looks like a toy. A reviewer who was not told the subject picked the ring and named it a fan or turbine. The outline square came second and is the backup.
- Numbers, in a 20-unit box centered on the hub, angles clockwise from the top. Each blade starts at radius 2.9, angle 0. It curves to radius 7.3, angle 38, with its control at radius 5.1, angle 5. It follows the circle to angle 68, then curves back to radius 2.9, angle 18, with its control at radius 5.1, angle 29. Hub radius 2. Ring radius 9, line width 1.3.
- The morph starts from a trace of Apple's `waveform.path.ecg` symbol at 14 points semibold (`research/vitals-pulse-morph.png`). Its line is 1.175 points thick and the ring is 1.17, so the line itself becomes the ring. The trace was fitted to the symbol's pixels automatically, which made it 14 times closer. In the real menu bar it differs from the real icon by 1.63 out of 255. Trace in points from the icon's center, y up: (-6.575, -0.9), (-3.4, -0.875), (-1.925, 5.775), (0.325, -6.625), (2.475, 2.75), (3.425, -0.875), (6.2, -0.9).
- Morph strokes: cut the long downstroke at its middle, which gives five strokes numbered left to right from 0. Going clockwise from the blade at 27 degrees, spaced 72 degrees apart, the blades take strokes 4, 3, 2, 0, 1. Blades 1 and 4 use their stroke backward. A search of every pairing found this one moves the strokes the least.
- Each stroke starts as a capsule the width of the line and morphs into the blade outline, point for point. Position and angle move from t 0 to 0.9 with no stagger, and the shape fattens from t 0.08 to 0.8. A scored search of pairings, routes and timing picked this: blade overlap through the middle of the morph fell from 1.14 to 0.70 square points on the fitted trace.
- The left and right tails move in polar coordinates to the ring's left and right halves from t 0.04 to 0.94, outer ends to the top, inner ends to the bottom. The hub grows from t 0.25 to 0.85, moving from the cut point to the center.
- All of those use a smootherstep curve. Drive t with a no-bounce spring (0.85 second response) so it can reverse at any moment. The live spin angle fades in from t 0.3 to 1, so there is no pause when the morph ends. On the way back, first reduce the spin angle to within 36 degrees, which is invisible because the blades repeat.
- Measured at 120 frames a second: the fastest point moves 62 points a second, down from 198 in the first morph, and the largest frame-to-frame speed change fell from 9,083 to 653. No part reaches past 8.1 points from the center, so nothing clips.
- Evan rejected blades that grow from the center: "the blades should come from the lines of vital".
- Rejected earlier: adding a rotation was disorienting, collapsing to a dot and regrowing was not a morph, and drawing the ring separately broke into pieces.
- Drawn in code next to the existing `MenuBarIcon` in `VitalsApp.swift`.
- Black-and-clear "template" images, so macOS colors it correctly on any wallpaper and in light or dark.
- The pulse and its needs-attention state stay exactly as they are.

## Staying light

The icon must not cause the heat it reports.

- Smoothness comes first: the spin runs on a Core Animation layer at the display's full refresh rate, up to 120 a second, outside the app's own code. Blur cross-fades between a sharp and a blurred copy of the blades.
- Tested in the real menu bar with a throwaway app on 2026-11-08 (`research/vitals-fan-real-menu-bar.png`). Swapping images at 60 a second used 20.4% of one core, which rules it out for the spin. The Core Animation spin used 0.03% in the app in a template image view (0.21% in the earlier full test), and WindowServer went from 45.0% to 45.8%, which is within its normal noise.
- The recipe that passed in the real menu bar. Put the blades in an `NSImageView` holding a template image, added inside the status button, so macOS colors them. A hand-colored layer came out too bright, 255 against the system's 230. Set the view layer's anchor point to its center and keep its position there.
- The status button is flipped, so a positive angle turns clockwise. The wrong sign scored 6.74, the right one 0.80, out of 255.
- For the handoff from the morph, start a rotation animation with an explicit `fromValue` of the current angle, and `toValue` one full turn more. Leaving out `fromValue` did not land on the right angle. With it, macOS showed exactly 10.00 and 28.00 degrees, and the pixels matched the drawn fan to 0.80 and 0.83 out of 255.
- To change speed, set `timeOffset` to the layer's current local time, `beginTime` to now, and `speed` to the new rate. Five live changes showed no jump beyond normal travel, and the largest timing error was 0.04 degrees.
- Still to confirm in the build: the icon's color when the wallpaper switches the menu bar between light and dark. It was only tested on the current dark bar.
- The morph is drawn live, as it was in the tests. Each frame depends on the live spin and blur, and it runs for about a second. Only the spin must stay on Core Animation.
- Pauses when the display sleeps or the menu bar is hidden in full screen.
- Target: under 1% of one CPU core while spinning. Measure it again in the real build. Speed updates run only while the speed is changing.
- With Reduce Motion on, the pulse cross-fades to a still fan, with no morph, spin or blur. The tooltip still gives the speed.

## Build steps

Start after the Memory tab work is merged. Work on a branch from `origin/main`. Check `git status` and open PRs first.

1. **Reader.** New `Sources/Vitals/FanReader.swift`, read-only. Reads the fan count, minimum, maximum and live speed from AppleSMC. It keeps one connection open. If the keys are missing, it reports "no fan" and the icon never appears. Add `--fan-live <seconds>`. Then run up to 5 minutes of heavy work, after telling Evan, so the live speed can be confirmed above 0.
2. **Behavior.** New `FanIndicator` logic with no drawing in it: show, smooth, coast, hide. Add `--selftest-fan` with made-up timelines (off, start, flicker, full speed, missing sensor) and add it to `scripts/check.sh`.
3. **Graphic.** Draw the frames. `--snapshot` only draws the panel, so add `--fan-frames <folder> --simulate-fan <rpm>` for PNGs of the icon. A second full Vitals cannot run beside the installed one, so add `--fan-bar-test` before the single-instance check for real menu bar tests. Check it on light and dark menu bars. Evan switches the wallpaper, because Vitals' rules forbid changing settings to test.
4. **Menu bar.** Wire it into `StatusItemController.refreshIcon`, including the morph, the attention dot, tooltip and VoiceOver label.
5. **Measure.** CPU while spinning, CPU while hidden, and no neighboring icon moving by even a pixel during the morph.
6. **Ship.** Add a section to `CONTRACT.md`, run `./scripts/check.sh`, open a PR, merge, install with `./scripts/build-app.sh`, then watch a real fan cycle: appears, tracks, leaves.

## Not included

- Controlling the fan. Vitals only reads it.
- A speed number in the menu bar.
- Fan history or a new panel tab.
- Notifications about the fan.

## Calls made for Evan to check

- Lives in Vitals, in the pulse icon's spot while the fan runs.
- 8 seconds before it leaves.
- White like the other menu bar icons, no color for high speed.
