# Den home screen

A custom home screen for Den (the TCL Fire TV in the den), replacing Amazon's.

- Canvas: https://claude.ai/artifact/58ebtcNJonzgiBtKWmRFuU (source in `project/`, publish with root = this folder)
- Brief (Evan, 2026-11-12): ONE design inspired by Apple TV and Roku, not a copy of either, not boring or minimal. Den is the main household TV: built for everyone, not one person. No ads, no banner, no forced rows, no one long app row.
- Direction: Home Team (`home-team-spec.json`), picked by a judged 3-concept round. Earlier A/B mockups are in git history.
- Rules it is checked against: `tv-ux-rules.md` (sourced).
- Apps and order: Den's own watch time (`dumpsys usagestats`, 2026-11-12), most watched first.
- Tiles use brand colours and names as stand-ins. A real build would use each app's own TV banner from Den.
- Open: whether our own app can take over Den's Home button (research running 2026-11-12). Nothing installed on Den.
