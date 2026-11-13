# Den home screen: roadmap (free tools only)

Written 2026-11-12, from a 9-agent research run with a fact-checker on each part, then the key claims re-checked
by hand (GitHub repos, issues and app permissions, and read-only reads of Den). Nothing has been installed on Den.

## Verdict

Worth doing, but configure first and build second. The design isn't the hard part. The Home button is, and no
app can fully take it over on Fire TV. One free test of about an hour answers that question, and it has a clean undo. If
it passes, use a free open-source home screen as-is, then add only the backdrop we designed. If it fails, stop
and tidy Amazon's own home screen. Either way nothing is lost.

## What was checked

| Claim | Checked how | Result |
|---|---|---|
| Fire TV apps can't take over the Home button | Amazon's developer docs | True. Every custom home screen uses a redirect: Amazon's home appears, then ours jumps in front. |
| A free redirect app works on Den's twin TV | Home on Fire issue #13 on GitHub | True. TCL 65QM64L, Fire OS 14, build AU105, the same build as Den (read from Den). |
| On that TV the Input button breaks | Same issue | True. The input list can't be used and our screen covers the HDMI picture. A fix is posted, not released. Den has no HDMI devices plugged in, so this doesn't bite today. |
| Settings bounces back from a custom home screen | Home on Fire issue #12 | Reported on Fire OS 8 only. Unknown on Den. |
| Amazon's home flashes for 0.4-0.9 s | Re-read issue #2 | **Corrected.** Those numbers were Home-press-to-our-screen times on older sticks. Nobody has timed Fire OS 14. Only Den can tell us. |
| Home on Fire can't reach the internet | Its AndroidManifest.xml | True. No internet permission. GPL-3.0, last release v1.5.2 (Sep 22), one maintainer. |
| LtvLauncher is a good free base | Repo, releases, manifest | True. GPL-3.0, 470 stars, updated today, no internet permission, Fire TV APKs. **Corrected:** its own Home fix covers Fire TV too, not only Google TV. |
| Den is clean | Read-only from Den | No other home screen app installed, no helper services on, one user account, Amazon's parental controls app present. |
| Amazon's free online Fire TV | Amazon FAQ | Unclear. The FAQ says both "all developers" and "select partners only". Sign in to see. |

Dropped by the fact-checkers: "a home screen app can't open Fire TV's input screen" (no source), and "turning off
Ambient Experience stops screensaver ads" (Amazon's own page says the ads come before Ambient).

Left out by the free-only rule: Projectivy (closed source, key features need $7.49 Premium, privacy can't be checked),
ATV Launcher Pro (paid), and a streaming box ($150-$299).

## The path

| # | Stage | Where | Touches Den | Status |
|---|---|---|---|---|
| 1 | Jobs list and pass/fail lines: who uses Den and their top jobs; the Step 0 checklist and undo | Mac | No | To do, about 30 min |
| 2 | Clickable prototype at TV size, arrow keys as the remote, Home flash simulated | Browser on Mac | No | **Done** (`research/den-home-screen/prototype/`) |
| 3 | Optional rehearsal of Step 0 on Amazon's free online Fire TV, if your account has it | Amazon's site | No | Needs your free sign-in |
| 4 | **Step 0 on Den**: Home on Fire pointed at LtvLauncher, checklist below | Den | **Yes, with your OK** | Waiting |
| 5 | Decision gate: compare results with the lines from stage 1 | Mac | No | |
| 6 | Live with LtvLauncher for a week; then the household, with a "got stuck" note by the TV | Den | Yes | |
| 7 | Prototype on Den's screen over AirPlay or HDMI, Mac keyboard as the remote; about 3 people per group get simple tasks with no hints | Den as a screen only | Nothing installed | |
| 8 | Only if the backdrop still matters: fork LtvLauncher and add our backdrop and glass band; test in the free Android TV emulator first | Mac, then Den | Last step only | Needs Android Studio + Flutter (free, ~10-15 GB, not installed) |
| 9 | After each Fire OS update: 5-minute re-check of Home, Settings, restart | Den | Read only | Ongoing |

## Step 0 checklist (on Den, real remote, about an hour)

Install Home on Fire v1.5.2 (checksum checked) and LtvLauncher, with LtvLauncher's own Home fix off. Only one
redirect app may run at a time. Test the undo first.

1. Home from inside an app: film 10 presses in slow motion and time them.
2. Settings opens and stays open.
3. Remote off and on, then a 30-second unplug: lands on our screen.
4. The escape: Home twice, slowly, reaches Amazon's home.
5. "Alexa, go home".
6. An app plays with sound, and Prime Video's controls hide on their own.
7. Input button (only matters once something is plugged into HDMI).
8. Profiles: if Den shows a profile picker or a kids profile, check a kid can't get stuck.
9. Den's speed scripts, run before and after.

Proposed pass lines (your call): Home lands on our screen within 1 second, Settings works, the escape works for an
older relative, nothing else breaks.

**Undo:** turn off "Replace Home button", uninstall both apps. Amazon's own home app is never touched.

## Risks

| Risk | Likely | Impact | Undo |
|---|---|---|---|
| Amazon's home flashes on each Home press | Certain | The length decides whether it's acceptable | Measure in Step 0; stop if too long |
| Input button and HDMI covered (seen on Den's twin) | Likely | None today, high once HDMI is used | Released fix, or redirect off |
| Settings bounces back | Unknown on Fire OS 14 | Older relatives get stuck | Escape gesture; redirect off |
| A Fire OS update breaks it (updates can't be turned off) | Any time | Den falls back to Amazon's home: safe, just ugly | Re-check; wait for a fix or stop |
| Home on Fire has one maintainer, untested officially on Fire OS 14 | Medium | No fix if it breaks | Back to Amazon's home |
| Always-on helper side effects (one report of lost sound) | Low | Confusing | Turn it off and compare |
| Ads outside the home screen stay | Certain | Low | None: the promise is "no ads on home" |
| Amazon is narrowing sideloading (newer devices can't) | Low for Den | Long-term | Reason not to over-invest |

## Your decisions

1. **OK Step 0 on Den** (about an hour, two free open-source apps, full undo).
2. The pass lines above: is up to 1 second of Amazon's home on each Home press acceptable?
3. When an app is added or removed: new apps go at the end automatically, or only when you add them?

## Sources

Amazon: developer.amazon.com/docs/fire-tv/remote-input.html, developer.amazon.com/docs/fire-tv/fire-os-14.html,
developer.amazon.com/docs/app-testing/live-device-interaction-virtual.html,
developer.amazon.com/docs/app-testing/appstore-quality-central-faq.html,
developer.amazon.com/docs/app-testing/measure-kpis-fire-tv-apps.html.
Launchers: github.com/toolicious/home-on-fire (issues 2, 12, 13, 14), github.com/LeanBitLab/LtvLauncher.
Process: nngroup.com (5 users, task scenarios, think aloud), dtg.org.uk 2025 study of viewers 65+, fxdigital.uk 10-foot
testing. Updates: aftvnews.com/amazon-patches-fire-tv-exploit, thestreamable.com/check-fire-tv-software-updates.
Full sourced research: the workflow output saved with this session (wf_f1dc77df-fe2).

## Step 0 results (run on Den 2026-11-12, then fully undone)

| Check | Result |
|---|---|
| Home from inside an app | Works, but Amazon's home, with its big promo banner, shows for about **1.3 s** first (15 timed presses from YouTube, Peacock and Hulu, plus a screen video). **Fails** the 1 s line. |
| Settings from our home screen | **Pass.** Opens and stays. |
| Input button | **Fail.** Amazon's input list gets pulled back to our screen in about 0.6 s. LtvLauncher's own "HDMI 1" opened Amazon Live TV instead. With the Xbox on HDMI 1, this blocks the setup. |
| Restart | Failed at first: TCL's software blocks the redirect from starting at boot. **Fixed** by allowing TCL's auto-start setting for the app; Den then booted onto our home screen. |
| Escape (double-press Home) | Unreliable with simulated presses (1 of 7). Needs a real-remote test. |
| Memory | Fine: about 19 MB and 56 MB. |
| Not tested (needs a person) | Alexa, sound in apps, real-remote long-press, kids profile. |

Den is back to its exact earlier state: both apps removed, settings match the backup.

**What would unblock it:** (1) a version of the redirect app that stands aside for the Input button. The fix is posted in home-on-fire issue #13 but not released; we could build it ourselves for free. (2) Or switching to the Xbox by turning it on, if Den follows the Xbox automatically over HDMI-CEC (untested). The 1.3 s flash has no fix on Fire TV.
