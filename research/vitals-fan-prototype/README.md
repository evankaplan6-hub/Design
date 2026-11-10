# Vitals fan: test code

Throwaway Swift used to prove the design in `plans/2026-11-08-vitals-menu-bar-fan.md`. It is reference only. Do not copy it into Vitals as it stands.

| File | What it proved |
|---|---|
| `fanprobe.swift` | Read-only AppleSMC fan reading, with the struct layout that works in Swift |
| `fit.swift` | Fits the pulse trace to the real `waveform.path.ecg` symbol |
| `routes.swift` | Search of stroke pairings, routes and timing for the morph |
| `metric.swift` | Scores a morph: point speed, speed change, reach, blade overlap |
| `realbar2.swift` | Final morph constants and full morph in the real menu bar. Its spin is superseded: hand-colored layers came out too bright and use the opposite sign. Use `realbar5.swift` for the spin. |
| `realbar4.swift` | Blades in a template image view: color and spin direction |
| `realbar5.swift` | Handoff with an explicit `fromValue`, and live speed changes |

The `realbar` files put a temporary icon in the menu bar on a made-up speed timeline, then quit. They take an output folder as their first argument.
