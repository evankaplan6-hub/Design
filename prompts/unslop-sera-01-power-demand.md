# First unslop of Sera: Power demand

Run in Claude Code from `~/sera`. Written 2026-11-02.

**On hold until sera PR #169 (stage 3, the chart dashboards) is merged.** It rewrites `grid.html` and `sera.css`, so run this on the new page, and check the file names below still match.

---

Use the unslop skill on Sera's Power demand page (`/grid`: `web/templates/grid.html`, data from `datasets/grid.py`; it has no page stylesheet yet). This is the first time unslop touches Sera, so treat it as a trial run of the skill as much as a fix to the page.

**Read first, in this order:** `CLAUDE.md`, `PRODUCT.md`, `DESIGN.md`, the "Phone layout" entry in `docs/feature-notes.md`, `docs/design/web-interface-guidelines.md` and `docs/design/references/`. Then read the unslop skill and its `references/signs.md` and `references/tokens.md`.

**Sera's locked design system wins over unslop wherever they disagree.** Sera is an Apple-style Operate surface, not vibecoded slop, so expect unslop's "light slop" polish mode, with the direction taken from the existing system. Specifically, keep:
- the system font, the 34px weight-700 page title and Sera's tracking (ignore unslop's font list, its 400 to 600 weight cap and its tracking rules)
- capsule buttons, chips and segmented controls, 22px cards and the other radii in `DESIGN.md`
- the rail's uppercase group labels (TECHNOLOGY, ENERGY and so on) and `.eyebrow`
- Apple blue as the one accent, and the `up`/`down` colors and their `-ink` text shades from `sera.css` (not unslop's semantic colors)
- no hero, no generated images, no new visual, no story video
- no new token, color, radius, shadow or font, and no edit to `sera.css`. Page CSS goes in a new `web/static/pages/grid.css` using only tokens, loaded through `{% block head %}`, with a `?v=` bump.

**What unslop should look at on this page:** spacing and alignment on the 4px scale; the four equal stat tiles ("Lower 48", "Last 91 days", "Texas, last 91 days", "Near a record 0") and whether each one reads on its own; the two charts side by side and whether one should lead; number formats and units (TWh vs GWh); copy (labels, the "this year against the same weekdays a year before" footers, the behind-schedule banner); hover and focus states; and motion. Copy follows Sera's own rules: no ellipses, no run-on sentences, card subtitles and tile labels fit one line on the iPhone 18 Pro Max (about 52 characters), every figure keeps its as-of date, and no page says "Sera".

**Stop after the audit and direction.** Give me the audit list from `signs.md` (one line each, with where it lives), mark which items the locked system overrides, write the five direction lines, and wait for my answer before editing anything.

**After I approve:**
1. Branch `design/unslop-grid` from a freshly fetched, clean `main`.
2. Run the page locally against a copy of the database in your scratchpad (never the real `data/sera.db`). Log in with `SERA_PASS` from `.env` without printing it.
3. Take before and after screenshots at Mac width (1440) and phone width (iPhone 18 Pro Max), in light and dark, and save them to `~/Design/audits/2026-11-unslop-grid/`.
4. Run `docs/design/phone-audit.mjs` on `/grid` and the full test suite (`uv run pytest -q`). Both must pass.
5. Stop every local server you started (`lsof -iTCP -sTCP:LISTEN` shows none of yours) and delete the database copy.
6. Commit, push and open a PR. Do not deploy; I'll say mnd when it's time.

**Report:** what changed in each pass, what you skipped because the locked system wins, the before and after screenshots, and a short note on which unslop rules clash with Sera's system, so the next page's prompt can leave them out.
