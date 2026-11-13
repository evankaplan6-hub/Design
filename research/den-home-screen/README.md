# Den home screen

A custom home screen for Den (the TCL Fire TV in the den), replacing Amazon's.

- Canvas: https://claude.ai/artifact/58ebtcNJonzgiBtKWmRFuU (source in `project/`, publish with root = this folder)
- Brief (Evan, 2026-11-12): Apple TV polish plus Roku-style big tiles. No ads, no banner, no forced rows, no one long app row.
- A: preview on top, 8 big tiles, 8 small tiles. B: side menu, 3-wide tile grid.
- Apps and order: Den's own watch time (`dumpsys usagestats`, 2026-11-12), most watched first.
- Tiles use brand colours and names as stand-ins. A real build would use each app's own TV banner from Den.
- Open: whether our own app can take over Den's Home button (research running 2026-11-12). Nothing installed on Den.
