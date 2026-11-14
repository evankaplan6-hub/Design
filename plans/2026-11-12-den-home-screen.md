# Den home screen: design plan (v2, after audit)

Den is the main household TV (TCL 65" Fire TV, Fire OS 14). Everyone uses it: adults, older relatives, kids, guests.
Brief (Evan, 2026-11-12): one design that looks like Apple TV and Roku put together. Not boring or minimal. No ads,
no rotating banner, no forced rows, no single long app row.

v1 was audited by an independent reviewer on 2026-11-12 (verdict: ready after fixes). v2 applies all 12 fixes.

## What the references actually look like (screenshots taken 2026-11-12)

- **Apple TV (tvOS 26)**, `research/den-home-screen/refs/apple-tv.png`: the focused app's artwork fills the screen.
  A frosted-glass band over the lower part holds the first row of wide rounded app icons, each a bold solid colour
  with a simple logo. The next row sits below the band on the artwork.
- **Roku (May 2026)**, `research/den-home-screen/refs/roku-2026.png`: deep purple, a header with "Roku · Home" top left
  and the time top right, a thin icon menu on the left, labelled sections ("Quick Access"), a grid of bright logo tiles
  4 across, a heading naming the focused tile, unused areas dimmed, and an ad column on the right.

**Taken from Apple TV:** full-screen backdrop that follows focus, the glass band, rounded polished tiles, the lift on focus.
**Taken from Roku:** deep purple, the labelled header bar, 4-across grid of big logo tiles, a heading that names the
focused app, dimming of the area not in use. **Dropped:** Roku's ads, recommendations and AI reordering; Apple's hint text.

## Step 0, before any mockup: test the Home button on Den (needs Evan's OK, touches the TV)

Install a tiny test app with the redirect method and check: pressing Home, leaving an app, after a restart, and how
long Amazon's home flashes first (rule 9: 250 ms). Also check input switching and what "Alexa, go home" opens.
If Home can't be made to land on our screen, Evan decides whether the project is still worth it before more design work.
Undo: uninstall the test app.

## Layout (1920x1080, safe area x 96-1824, y 54-1026)

1. **Backdrop:** the focused app's art, full screen, cross-fading 250 ms after focus rests 150 ms. Its real form on Den
   is the app's banner enlarged, blurred, darkened and tinted deep purple, brightness capped so no large white area
   ever appears. Rich artwork only if Fire OS lets a launcher read Watch Next art (assume it doesn't).
2. **Header bar, y 54-118 (Roku style):** on the left, text buttons "Inputs", "Settings", "All apps"; on the right, the
   time on a glass pill. Up from any tile in row 1 lands on "Inputs"; Down returns to the tile you came from.
3. **Heading, above the grid:** the focused app's name, 40 px, like Roku's heading over its grid.
4. **Glass band:** starts at y 390, deep-purple tinted glass, at least 70% dark. It holds row 1; when you move down,
   the band rises with the grid and fills the screen, and the backdrop above dims.
5. **App grid, 4 across:** tiles 392x221 (16:9), 40 px between columns, 100 px between rows, spanning x 116-1804.
   - Row 1 at y 420-641, row 2 at y 741-962. About 18 px of row 3 shows at the bottom edge as a "more below" cue
     (it sits in the outer margin; Evan to accept or reject).
   - Order comes from Den's own watch-time data (`dumpsys usagestats`, read 2026-11-12) and is **locked**: it never
     reshuffles itself, so older relatives can find apps by position.
   - Row 1: Hulu, Peacock, Disney+, HBO Max. Row 2: YouTube, CNBC, Paramount+, Prime Video.
     Row 3: Spotify, Apple TV, NBA, ESPN. Row 4: DAZN, FOX One, Netflix, MLB. Every tile has a tile straight below
     it until the last row, so Down never dead-ends.
6. **Tiles:** each app's own TV banner (real banners pulled from Den for the mockup, never invented art). Rounded
   corners 24 px, slight top highlight like Apple's icons. Every tile shows its name underneath at 28 px, dimmed;
   the focused tile's name brightens to 32 px.
7. **Focus:** 1.08x lift (keeps edge tiles inside the safe area), a 4 px white outer ring with a 2 px dark inner ring
   so it shows on white banners too, and a soft shadow. One item focused at a time.
8. **Back:** on the home screen, Back does nothing (it never exits to Amazon's home). Returning from an app or Alexa
   puts focus on the tile last launched.
9. **Alexa:** the remote's mic button stays with Fire OS. "Alexa, go home" probably opens Amazon's home: tested in step 0.

## Type and colour

- Font: Albert Sans (Google Fonts), close to Apple's system look. Time 56 px, heading 40 px, names 28-32 px, nothing under 28 px.
- Colour: deep purple glass and tint (Roku), bright app tiles, white focus ring. Text #F2F2F5 on glass at least 70% dark,
  checked for 4.5:1.

## Rules it must pass (`research/den-home-screen/tv-ux-rules.md`)

Safe area 96/54 (edge tile at 1.08x plus ring reaches x 96.3 and 1823.7); text 28 px minimum; contrast 4.5:1;
one obvious focus at up to 1.1x with an outline; straight-line D-pad moves (Up from row 1 to the header, no diagonals);
most-used first, locked order, no sponsored rows; nothing autoplays; responds within 250 ms; Back never traps or exits.

## Real build constraints (Den: 2.4 GB RAM, weak GPU)

- No live blur. Each backdrop is pre-blurred once and stored at 480x270 (about 0.5 MB); only the current and next
  ones stay in memory, the rest on disk. The band is cut from the same image.
- Banners are 320x180; at 392x221 they're scaled up about 1.2x, more at 1.08x focus. Acceptable softness, check on Den.
- Inputs: a sideloaded launcher may not be allowed to switch HDMI inputs; tested in step 0, else the button opens
  Fire OS's own Inputs screen.

## Steps

0. Home button and inputs test on Den (Evan's OK first).
1. Evan approves this plan.
2. Pull the real app banners from Den (read-only) and build the mockup on the canvas.
3. Evan reviews it; then decide on building the real app.
