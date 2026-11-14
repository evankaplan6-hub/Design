# TV home screen rules (research 2026-11-12, fact-checked)

Home screen rules for the family TV (Den, TCL 65" Fire TV)

Fire TV draws its 1080p screen at 1920x1080 px, which is 960x540 dp, so 1 dp = 2 px. dp is the Android design unit. Some Fire TV devices draw a 720p screen, so size things in dp rather than fixed pixels [1][2].

The 12 rules

1. Safe edges: keep all text, buttons and tiles out of the outer 5% of the screen. That means 96 px from the left and right and 54 px from the top and bottom. Backgrounds can still run to the edge [1][3].
2. Text size: body text should be at least 28 px. Treat that as the smallest size you allow, and use 28 to 36 px for most text. Avoid fonts that are too cursive or too light [1][9][10].
3. Colour and contrast: use a dark background with no large white areas. Pick softer, cool colours (blue, purple, gray) rather than red or orange. Text must contrast with its background by at least 4.5:1, or 3:1 for large text [12][1][10][11].
4. Focus: only one tile is highlighted at a time, and it should be obvious even after someone looks away. Grow the tile by up to 1.1x (a 392 px tile becomes about 431 px) and add a border. Never show focus by colour alone, and never move the highlight unless the person pressed a button [13][14][1][15].
5. Tile size and spacing: with 4 tiles in a row, make each tile 392 px wide with 40 px gaps, in a 16:9 shape. Leave at least 100 px between rows so a grown tile never covers its neighbour [16][3][4].
6. Remote moves: up and down move between rows, and left and right move along a row. Every tile must be reachable in a straight line [17][1].
7. Keep it short: put few things on screen and put the household's most-used apps first. A side menu should have 5 to 6 items at most. Leave out sponsored rows, which users say make apps harder to find [1][18][19].
8. Real labels: every tile and icon needs a plain text name. Don't rely on text inside the artwork. App banners are 320x180 px and must show the app's name [22][23][24].
9. Fast response: react to every button press, and every move between tiles, within 250 ms. If something takes more than 3 seconds, show a loading sign [25][27].
10. Nothing plays by itself: no autoplaying video and no sound on the home screen. Anything that moves for more than 5 seconds needs a way to pause or stop it [20][21].
11. Back and Home: Back always goes to the previous screen and never loops or traps anyone. On Fire TV the Home button always goes to the system Home screen, and an app cannot take over that button. Plan around this [17][28].
12. Voice: make Alexa voice search an easy main path, because it beat program guides for viewers aged 65 and over. Don't make it the only path. When Alexa closes, put people back where they were [29][30][31].

Where the sources disagree

- Safe edges: Amazon says 96/54 px [1]. Apple says 80 px on the sides and 60 px top and bottom [4]. Roku's text says 90/60 px, but its own action-safe zone is 96/53 px [5][6]. Google's page contradicts itself, giving 96/54, 96/48 and 116/56 px [3]. On a Fire TV, follow Amazon: 96/54 px. For text, Roku's stricter text-safe area (192 px on the sides, 106 px top and bottom) is a cautious extra option on a 65-inch shared TV [6].
- Smallest text: Apple says 23 px [7], old Google guidance says 24 px [8] and Amazon says 28 px [1]. On a Fire TV, follow Amazon's 28 px.
- Tile width for 4 per row: Google uses 392 px [16] and Apple uses 410 px [4], both with 40 px gaps. Follow Google. Its row (4 x 392 + 3 x 40 = 1688 px) fits inside Amazon's 1728 px safe width. Apple's 1760 px row does not.
- Contrast: Amazon and Apple say at least 4.5:1 [10][11]. One designer suggests 7:1 for viewers with weaker eyesight [9]. Follow 4.5:1 as the minimum.

Not checked: the real screen size and density Fire OS 14 uses on the TCL set. The 1 dp = 2 px rule assumes the 1080p canvas.

Sources

1. Design and User Experience Guidelines (Fire TV), https://developer.amazon.com/docs/fire-tv/design-and-user-experience-guidelines.html, last updated Oct 29, 2020
2. Display and Layout (Fire TV), https://developer.amazon.com/docs/fire-tv/display-and-layout.html, last updated Oct 30, 2026
3. Layouts (Android TV design), https://developer.android.com/design/ui/tv/guides/styles/layouts, last updated 2025-05-09
4. Layout, Apple Human Interface Guidelines, https://developer.apple.com/design/human-interface-guidelines/layout, 2026-09-09
5. Key Design Principles (Roku), https://developer.roku.com/dev/docs/key-design-principles, updated 2026-11-04
6. Streaming Store graphics (Roku), https://developer.roku.com/docs/specs/graphics.md, updated 2026-11-04
7. Typography, Apple Human Interface Guidelines, https://developer.apple.com/design/human-interface-guidelines/typography, 2025-12-16
8. Style for TV (archived Android design doc), https://android.googlesource.com/platform/frameworks/base/+/114aeea/docs/html/design/tv/style.jd, undated (commit 2017-01-19)
9. Solving small text and contrast issues for large-screen readability (alicia.design), https://www.alicia.design/post/solving-small-text-and-contrast-issues-for-large-screen-readability, 2025-12-03
10. Accessibility Guide for Web Apps (Amazon Vega Docs 0.24), https://developer.amazon.com/docs/vega/0.24/webview-accessibility-guide.html, updated 2026-05-20
11. Accessibility, Apple Human Interface Guidelines, https://developer.apple.com/design/human-interface-guidelines/accessibility, 2025-06-09
12. Color on TV (Android TV design), https://developer.android.com/design/ui/tv/guides/foundations/color-on-tv, last updated 2023-06-04
13. Focus system (Android TV design), https://developer.android.com/design/ui/tv/guides/styles/focus-system, last updated 2024-03-21
14. Color, Apple Human Interface Guidelines, https://developer.apple.com/design/human-interface-guidelines/color, 2025-12-16
15. Focus and selection, Apple Human Interface Guidelines, https://developer.apple.com/design/human-interface-guidelines/focus-and-selection, 2023-10-24
16. Cards (Android TV design), https://developer.android.com/design/ui/tv/guides/components/cards, last updated 2026-03-30
17. Navigation on TV (Android TV design), https://developer.android.com/design/ui/tv/guides/foundations/navigation-on-tv, last updated 2025-05-09
18. Navigation drawer (Android TV design), https://developer.android.com/design/ui/tv/guides/components/navigation-drawer, last updated 2026-03-30
19. New Fire TV Interface Update Sparks User Backlash (TROYPOINT), https://troypoint.com/amazon-fire-tv-interface-gets-biggest-update/, 2026-03-23
20. 4 ways I cleaned up my Fire TV's cluttered home screen (XDA Developers), https://www.xda-developers.com/ways-i-cleaned-up-my-fire-tvs-cluttered-home-screen/, 2026-09-08
21. Understanding Success Criterion 2.2.2: Pause, Stop, Hide (W3C), https://www.w3.org/WAI/WCAG22/Understanding/pause-stop-hide.html, undated (page last updated 2026-10-04)
22. Smart-TV Usability: Accessing Content is Key (Nielsen Norman Group), https://www.nngroup.com/articles/smart-tv-usability/, 2015-09-20
23. Evaluation of smart TV user interfaces for older adults (Frontiers in Psychology), https://pmc.ncbi.nlm.nih.gov/articles/PMC13500268/, 2026-08-10
24. TV app quality guidelines (Android), https://developer.android.com/docs/quality-guidelines/tv-app-quality, last updated 2026-06-29
25. Certification criteria (Roku), https://developer.roku.com/dev/docs/certification, updated 2026-10-05
26. (not used)
27. Design for TV (Android TV design), https://developer.android.com/design/ui/tv/guides/foundations/design-for-tv, last updated 2023-05-08
28. Remote Control Input (Fire TV), https://developer.amazon.com/docs/fire-tv/remote-input.html, last updated Feb 19, 2026
29. Simple changes make streaming TV easier for older viewers (Goldsmiths, University of London), https://www.gold.ac.uk/news/2025/iptv-usability-design/, 2025-09-19
30. Considerations for TV user interface accessibility (TetraLogical), https://tetralogical.com/blog/2023/08/09/tv-accessibility-considerations/, 2023-08-09
31. Controller Behavior Guidelines (Fire TV), https://developer.amazon.com/docs/fire-tv/controller-behavior-guidelines.html, last updated May 30, 2025

Every number above comes from the fact-checked sourced rules I was given. I did no new research and added nothing from memory. I worked out the only new arithmetic myself: the 1688 px row and 1728 px safe width, and the 431 px focused tile.
