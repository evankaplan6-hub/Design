# Den home screen

A custom home screen for Den (the TCL Fire TV in the den), replacing Amazon's.

- Canvas: https://claude.ai/artifact/58ebtcNJonzgiBtKWmRFuU (source in `project/`, publish with root = this folder)
- Brief (Evan, 2026-11-12): ONE design inspired by Apple TV and Roku, not a copy of either, not boring or minimal. Den is the main household TV: built for everyone, not one person. No ads, no banner, no forced rows, no one long app row.
- Direction: Home Team (`home-team-spec.json`), picked by a judged 3-concept round. Earlier A/B mockups are in git history.
- Rules it is checked against: `tv-ux-rules.md` (sourced).
- Apps and order: Den's own watch time (`dumpsys usagestats`, 2026-11-12), most watched first.
- Tiles use brand colours and names as stand-ins. A real build would use each app's own TV banner from Den.
- Home button (research 2026-11-12): maybe. Amazon's docs say apps can't take over Home; a redirect method is reported working on Den's twin (TCL 65QM64L). Details in the home-tv-support skill's den-modding.md. Nothing installed on Den.
