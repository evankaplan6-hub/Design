# Sera for iPhone (Xcode/Swift) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Home Screen web app with a native iPhone app: a SwiftUI shell around Sera's existing pages first (Phase 1), then native push notifications (Phase 2), then native features only where the web can't do the job (Phases 3 and 4).

**Architecture:** The Python server (FastAPI on Fly, `sera-desk`) stays the backend and keeps serving every page. The app is a client. Phase 1 puts each of the five phone tabs in its own `WKWebView` under a native SwiftUI `TabView`, and the server hides its own web tab bar when the app loads a page. Phase 2 adds Apple Push Notification service (APNs) next to the existing Web Push, because a `WKWebView` inside an app gets no Web Push. No page is rewritten in Swift until Phase 4, and then only one at a time.

**Tech Stack:** Swift 6, SwiftUI, WebKit, UserNotifications, Xcode 27.2, iOS 27 SDK. Server side: Python 3, FastAPI, `cryptography` (already a dependency), `httpx[http2]`.

**Spec:** No separate spec exists. Part 1 below is the spec: what was found in the code on 2026-11-07, and the decisions taken from it. Evan's request: "i want u to make a plan" for moving Sera to Xcode/Swift.

**Audit:** A separate reviewer checked revision 1 against `~/sera` `origin/main` `4aff70c` and Apple's docs on 2026-11-07. All 16 findings are fixed in this revision.

**Revision 3 (2026-11-07), free start:** Evan asked whether there's a trial. There isn't, but Phase 1 needs nothing the paid program gives. So Phase 1 is now built and used on Xcode's free Personal Team, and the $99 is paid only when Phase 2 starts. A second reviewer checked this revision against Apple's docs. Its fixes are in: pairing in Xcode 27's Device Hub, the steps in the right order, an install script that builds for the phone and always targets the live box, the one-time "Trust" step, and a Phase 2 gate that isn't circular.

## Part 1: Findings and decisions

### What exists (checked 2026-11-07 against `~/sera` main `4aff70c`)

- **Server:** `sera/app.py` has 744 lines. There are 90 page modules in `pages/`, 125 Jinja templates in `web/templates/`, one `web/static/sera.css` (1,291 lines) and one `sera.js` (875 lines). JSON already exists for:
  - any registry page (`/api/page/{slug}`)
  - search (`/api/search`, `/api/command`)
  - live quotes (`/api/live` server-sent events, `/api/quote`)
  - health and the watchlist
- **Login:** `sera/auth.py`: one password, a year-long HMAC cookie `serasession`, a one-click link, and a 6-digit pairing code (`POST /api/pair`, entered at `/login`). `/api/*` answers 401 JSON when logged out.
- **Phone today:** a Home Screen web app.
  - `sera.js` lines 17-51 add pull-to-refresh and a 10-minute reload in standalone mode.
  - Lines 56-83 set the icon badge and subscribe to Web Push. `syncPush` re-sends the subscription once a day, naming the device `iPhone (Home Screen app) · <date>`.
  - `sw.js` shows pushes, sets the badge, opens the pushed URL on a tap and draws an offline page.
- **Push:** `sera/push.py` is standard Web Push (VAPID, aes128gcm), stored in table `push_subs`.
  - Senders: `datasets/alerts.py:1123` (`pushcopy.payload(ev)` → `{title, body, url, tag, urgent}`), `:1126` (the daily cap note), `datasets/morning.py:927` (the morning brief) and `sera/app.py:205` (the test push).
  - Both dataset senders first check whether any device exists by counting `push_subs` directly (`alerts.py:1111`, `morning.py:924`).
  - `send_all` adds `badge` (the unseen alert count). `missing_phone()` drives the home page's "No phone is paired" warning.
  - Alerts are marked seen only when `/alerts` is loaded (`pages/alerts.py:38`).
- **Settings page:** `sera/alertsview.py:591-597` builds the device list from `push_subs` directly. Its Remove button (`alerts_settings.html:82`, `web/static/pages/alerts.js:105-107`, linked as `alerts.js?v=8`) posts an `endpoint`. `alerts.js:68` shows "Add to Home Screen" steps when the page has no `PushManager`.
- **Docker:** `.dockerignore` is an allowlist (`sera/`, `datasets/`, `pages/`, `web/`), so a new `ios/` folder never reaches the image.
- **Mac toolchain:**
  - Xcode 27.2 with the iOS 27.2 SDK.
  - **No iOS simulator runtime is installed** (`xcrun simctl list runtimes` is empty).
  - **No code-signing identity and no provisioning profiles** (`security find-identity` finds 0).
- **Your only Swift project:** Vitals (`~/claude/vitals`), a macOS Swift package. An iOS app can't be a bare Swift package: it needs an `.xcodeproj`.

### Decisions

1. **A shell first, not a rewrite.**
   - Rewriting 90 pages and 125 templates in SwiftUI would take months, and every collector, alert rule and page would then exist twice. ETHOS.md asks for simple architecture.
   - The shell gives native tabs, swipe-back, pull-to-refresh and push in weeks. Native screens come later, one at a time, and only where they beat the web page (Phase 4).
2. **Phase 1 is free; native push costs $99 a year.**
   - A `WKWebView` in an app gets no Web Push, so without APNs the app would push *less* than the Home Screen app does today.
   - APNs, TestFlight, and installs that last more than 7 days all need the paid Apple Developer Program. Apple has no trial, and waives the fee only for nonprofits, schools and governments.
   - Phase 1 needs none of those. It runs on Xcode's free Personal Team (any Apple ID). The cost is reinstalling from the Mac every 7 days, which `ios/scripts/install.sh` makes one command (Task 3).
   - Through Phase 1, the Home Screen app stays on the phone and keeps delivering pushes.
   - **Phase 0b (enrollment and APNs keys) is a hard gate for Phase 2.** If Evan doesn't enroll, the project stops after Phase 1, and he keeps both the app and the Home Screen app.
3. **The app lives in the Sera repo, in `ios/`.** Server and app changes that depend on each other land in one PR. The Docker allowlist already keeps `ios/` out of the image.
4. **A plain Xcode project with folder-synchronized groups.** No XcodeGen, and no third-party Swift packages.
5. **One `WKWebView` per tab, sharing `WKWebsiteDataStore.default()`.**
   - Each tab keeps its own back stack and scroll position.
   - One login cookie serves all five.
   - Tabs load lazily, the first time they're selected. Loading Alerts at launch would mark every alert seen before Evan reads it.
6. **The server knows it's the app from the user agent.**
   - The app appends `SeraApp/1` (`WKWebViewConfiguration.applicationNameForUserAgent`, added after `Mobile/15E148`).
   - The server puts `class="in-app"` on `<html>`. CSS and JS change only inside the app, so Safari and the Mac stay the same.
7. **Distribution: TestFlight internal testing, never the App Store.**
   - FINRA's data is non-commercial and Sera is private.
   - Internal TestFlight builds skip App Review, update over the air and last 90 days.
   - Phase 1 can be a direct Xcode install.
8. **Bundle ID `com.evankaplan.sera.dev` on the free team; `com.evankaplan.sera` from Phase 2 on the paid team. Minimum iOS 27.0, iPhone only, portrait only.**
   - An App ID registered by the free Personal Team belongs to that team, which is not the paid team Evan gets on enrolling. There's no way to release it yourself: Apple's own advice is to change the bundle ID (developer.apple.com/forums/thread/843925, August 2026). Keeping `com.evankaplan.sera` unused until then means the paid team can register it without a clash.
   - The switch in Task 6 is one build setting plus deleting the `.dev` app from the phone.
   - In landscape a Pro Max is about 956 points wide. That's over the 900 px breakpoint, so the Mac rail and top bar would appear inside the app.
   - Landscape waits until a native screen (Phase 4) needs it.
   - Tests run on the iPhone 18 Pro Max simulator only (Evan's rule).
9. **One phone, one push channel.**
   - When the app registers for APNs, the server deletes the `push_subs` rows named `iPhone (Home Screen app)`.
   - While an APNs device exists, the server refuses new subscriptions with that name, so the old icon's daily re-sync can't bring them back.
   - Evan deletes the Home Screen icon once the app's first push lands. Mac and Safari subscriptions stay.
10. **APNs keys never pass through Claude.** Evan pastes them into `ops/set-apns-key.sh` (a hidden prompt, like the other `ops/set-*-key.sh` scripts), which sets the Fly secrets.
11. **One APNs key per environment.** Apple now restricts new keys to either sandbox or production. Xcode installs use sandbox and TestFlight uses production, so the server reads `APNS_KEY_ID_SANDBOX`/`APNS_KEY_P8_SANDBOX` and `APNS_KEY_ID_PRODUCTION`/`APNS_KEY_P8_PRODUCTION`, with a shared `APNS_TEAM_ID`.

### Phases

| Phase | Ships | Gate to start |
|---|---|---|
| 0a | Simulator, free Personal Team, phone paired (free) | none |
| 1 | Native shell on Evan's iPhone, with the web pages inside (free) | Phase 0a done |
| 0b | Paid enrollment, APNs keys ($99 a year) | Evan decides the app is worth keeping |
| 2 | Native push, badge, notification taps, TestFlight | Phase 0b Steps 1-3 done, Phase 1 used for a few days |
| 3 | Widget and App Intents (candidates; each gets its own plan) | Phase 2 has pushed reliably for a week |
| 4 | Native screens one at a time (candidates; each gets its own plan) | a measured problem with a web page in the app |

## Global Constraints

- **Backend:** the Python server stays the backend. No collector, alert rule or page logic moves into Swift.
- **App build:**
  - Swift 6 language mode, SwiftUI, deployment target iOS 27.0, iPhone portrait only, no third-party Swift packages.
  - Bundle ID `com.evankaplan.sera.dev` in Phase 1 (free team), `com.evankaplan.sera` from Task 6 (paid team). User agent token `SeraApp/1`.
  - Server base URL `https://sera-desk.fly.dev`. A Debug build reads `SERA_BASE_URL` from Info.plist, so a local server (`http://127.0.0.1:8080`) works.
- **Simulator:** iPhone 18 Pro Max only.
- **Writing rules, for every string in the app too:**
  - No ellipses, no run-on sentences, and labels fit one line on the Pro Max (`tests/test_no_ellipsis.py` covers the server side).
  - Copy never talks about Sera, its server or its collectors (`sera-finished-look`). An error view says what happened and what to do, nothing else.
- **Static files:** any edit to a file in `web/static/` bumps its `?v=` everywhere it's linked, `login.html` included (`tests/test_static_versions.py`).
- **Safari and the Mac stay unchanged:** every server-side change is gated on `in-app` or is a new route.
- **Project rules (`CLAUDE.md`):**
  - Edit `CLAUDE.md` only; `AGENTS.md` is a symlink to it.
  - Each PR adds its own line in `docs/feature-notes.md`.
  - UI changes follow the "Phone layout" note and run `docs/design/phone-audit.mjs`.
  - A local server started for a check is stopped afterwards.
- **Server checks:** `uv run pytest -q` (the full suite) passes before any PR. Deploy through the `sera-deploy` skill.
- **App checks:** `xcodebuild test -project ios/Sera.xcodeproj -scheme Sera -destination 'platform=iOS Simulator,name=iPhone 18 Pro Max'` passes before any PR.
- **Keys:** never handle Evan's keys or passwords. The APNs `.p8` files, `SERA_PASS` and the login link stay with him. Check secrets by name only (`fly secrets list`), never by value.

## Review Focus

1. **The same alert pushed twice**, when the Home Screen app and the native app are both subscribed.
   - Fix: Decision 9.
   - Pinned by `test_register_replaces_home_screen_rows_only` and `test_home_screen_subscribe_is_refused_while_the_app_is_paired` (Task 5).
2. **No alert reaches a phone that has only the native app**, because the dataset senders count `push_subs` only.
   - Fix: `push.has_device`.
   - Pinned by `test_alert_reaches_an_apns_only_phone` and `test_morning_brief_reaches_an_apns_only_phone` (Task 4).
3. **A device token sent to the other environment's host.** APNs answers 400 `BadDeviceToken` and pushes stop without a sound.
   - Fix: store each device's environment and send to its host with its environment's key. On a 400, keep the row with `last_error` set; only a 410 deletes it.
   - Pinned by `test_sandbox_device_goes_to_sandbox_host_with_the_sandbox_key` and `test_bad_device_token_keeps_the_row` (Task 4).
4. **A notification tapped while the app is closed.** The URL arrives before any web view exists.
   - Fix: the router holds it and opens it once the tab is up.
   - Pinned by `coldLaunchURLIsHeldUntilTabsExist` (Task 6).
5. **Logged out** (the cookie is gone, or `SERA_PASS` changed).
   - Every tab shows `/login`, and push registration gets a 401.
   - Fix: logging in on one tab reloads the other tabs, and the registrar retries after the next logged-in page load.
   - Pinned by `loginOnOneTabReloadsTheOthers` (Task 3) and `registrationRetriesAfterUnauthorized` (Task 6).

---

## Phase 0a: Free setup (about 20 minutes, no payment)

Steps 2 to 4 need Evan's Apple ID or his phone, so Claude can't do them. Step 1 Claude can run.

- [ ] **Step 1: Install the iOS simulator runtime** (about 8 GB). If it says no runtime matches, add `-architectureVariant arm64`.

```bash
xcodebuild -downloadPlatform iOS
```

Expected: `xcrun simctl list devices available | grep "iPhone 18 Pro Max"` prints a device.

- [ ] **Step 2: Sign in to Xcode with your Apple ID:** Xcode > Settings > Accounts > +. A "Personal Team" appears. It's free and can sign apps for your own devices.
- [ ] **Step 3: Pair the phone with the Mac.** In Xcode, open Device Hub (Xcode > Open Developer Tool > Device Hub). Either click + > Pair Nearby Device with the phone unlocked next to the Mac, or plug it in with a cable and click Pair. Tap Trust on the phone and enter its passcode.
- [ ] **Step 4: Turn on Developer Mode.** The setting only appears after pairing. On the phone: Settings > Privacy & Security > Developer Mode, turn it on, tap Restart, then after the restart tap Enable and enter the passcode.

After pairing, installs work over Wi-Fi whenever the phone and Mac are on the same network. Two catches:
- The Wi-Fi network must have IPv6 turned on. Most home routers do by default.
- **Every iOS update unpairs the phone.** After one, pair again in Device Hub (Step 3) before the next reinstall.

What the free team can't do, so the plan doesn't use it before Phase 2: push notifications, Time Sensitive notifications, TestFlight, and anything that lasts more than 7 days. Its other limits: 3 free-team apps on the phone at once, 3 registered devices, and 10 App IDs, each expiring after 7 days. Vitals is a Mac app, so it doesn't use a slot on the phone.

---

## Phase 1: The native shell

### Task 1: The server marks pages loaded by the app

**Files:**
- Create: `sera/appshell.py`
- Modify: `sera/app.py:40` (the `_nav_context` context processor returns `in_app`)
- Modify: `web/templates/base.html:2` (`<html lang="en"{% if in_app %} class="in-app"{% endif %}>`), plus `:16` and `:102` (`?v=` bumps)
- Modify: `web/templates/login.html:16` (`sera.css?v=` bump), and `alerts_settings.html:102` (`alerts.js?v=9`)
- Modify: `web/static/sera.css` (an `.in-app` block next to the `display-mode: standalone` rules at lines 461-465)
- Modify: `web/static/sera.js` (lines 20, 60 and the live-quote stream near line 710), `web/static/pages/alerts.js:68`
- Modify: `web/templates/hubs.html:40` (no theme button in the app)
- Modify: `docs/feature-notes.md` (one entry under "Phone layout")
- Test: `tests/test_appshell.py`

**Interfaces:**
- Produces:
  - `appshell.in_app(user_agent: str | None) -> bool`
  - `appshell.UA_TOKEN = "SeraApp/"`
  - the template variable `in_app`
  - the `html.in-app` class, which Task 2's app relies on

- [ ] **Step 1: Write the failing tests.** Define the file's own fixture, as `tests/test_app.py:11-37` does: a module `TestClient` with the throwaway database and no Yahoo calls, logged in with `client.cookies.set(auth.COOKIE, auth.session_token())`. An unauthenticated request is redirected to `/login`, which doesn't extend `base.html`, so the test would fail for the wrong reason.

```python
APP = "Mozilla/5.0 (iPhone) AppleWebKit/605.1.15 Mobile/15E148 SeraApp/1"
SAFARI = "Mozilla/5.0 (iPhone) Version/27.0 Mobile/15E148 Safari/604.1"

def test_app_user_agent_marks_the_page(client):
    assert '<html lang="en" class="in-app">' in client.get("/", headers={"User-Agent": APP}).text

def test_safari_page_has_no_app_class(client):
    assert 'class="in-app"' not in client.get("/", headers={"User-Agent": SAFARI}).text

def test_in_app_needs_the_token():
    assert appshell.in_app("x SeraApp/1") and not appshell.in_app(None) and not appshell.in_app("Sera")

def test_more_tab_has_no_theme_button_in_the_app(client):
    assert "data-theme" not in client.get("/hubs", headers={"User-Agent": APP}).text
```

Adjust the last assertion to the theme button's real attribute in `hubs.html:40`.

- [ ] **Step 2: Run them to see them fail.** Run: `uv run pytest tests/test_appshell.py -q`. Expected: 4 failed.
- [ ] **Step 3: Implement `in_app`, and return it from `_nav_context(request)`** as `in_app=appshell.in_app(request.headers.get("user-agent"))`.
- [ ] **Step 4: Add the `.in-app` CSS.**
  - Hide `.tabbar`, since the native tab bar replaces it.
  - Hide `.rail` and the Mac top bar at every width. They're portrait-locked anyway, but this guards against a mistake.
  - Replace the tab bar's bottom padding with `env(safe-area-inset-bottom)`, so the last rows clear the native tab bar.
  - Leave out the standalone `min-height` and `--sat` rules: the web view starts below the status bar.
- [ ] **Step 5: Gate the JS on `document.documentElement.classList.contains("in-app")`.**
  - `sera.js`: skip the pull-to-refresh and background-reload block (line 20), and the service worker and `syncPush` (line 60). The app does all three natively.
  - `sera.js`: close the live-quote `EventSource` on `visibilitychange` to hidden, and reopen it on visible, so the four tabs Evan isn't looking at don't poll `/api/live` every 2 seconds.
  - `alerts.js:68`: don't show the "Add to Home Screen" steps.
  - `hubs.html`: leave out the theme button. The app follows the system appearance, so the page and the native tab bar always agree.
  - Bump every `?v=` touched.
- [ ] **Step 6: Run the full suite.** Run: `uv run pytest -q`. Expected: all pass, `test_static_versions.py` included.
- [ ] **Step 7: Run the phone audit** (`docs/design/phone-audit.mjs`) to confirm Safari's phone layout is unchanged.
- [ ] **Step 8: Add a "Phone layout" feature-notes line and commit.** `git commit -m "App shell: pages loaded by the iPhone app hide the web tab bar and leave refresh and push to the app"`

### Task 2: The Xcode project, tabs and link policy

**Files:**
- Create, with Xcode's iOS App template (SwiftUI, Swift Testing, folder-synchronized groups): `ios/Sera.xcodeproj`, `ios/Sera/SeraApp.swift`, `ios/SeraTests/`
- Create: `ios/Sera/SeraTab.swift`, `ios/Sera/LinkPolicy.swift`, `ios/Sera/AppConfig.swift`
- Create: `ios/README.md` (how to build, test and install)
- Modify: `.gitignore` (`ios/**/xcuserdata/`, `ios/build/`, `ios/Local.xcconfig`)
- Modify: `CLAUDE.md` only, never the `AGENTS.md` symlink. Add one line under the phone rules: "The iPhone app lives in `ios/`; read `ios/README.md` first."
- Test: `ios/SeraTests/SeraTabTests.swift`, `ios/SeraTests/LinkPolicyTests.swift`

**Interfaces:**
- Produces:
  - `enum SeraTab: String, CaseIterable { case today, market, search, alerts, more }`, with:
    - `var path: String`: `"/"`, `"/h/market"`, `"/search"`, `"/alerts"`, `"/hubs"`
    - `var title: String`: `"Today"`, `"Market"`, `"Search"`, `"Alerts"`, `"More"`
    - `var symbol: String`: an SF Symbol
    - `static func owning(_ url: URL) -> SeraTab?`: only `/alerts` and `/search` paths claim a tab; everything else stays in the current one
  - `enum LinkAction: Equatable { case load, openExternally, switchTab(SeraTab, URL) }`
  - `func decide(_ url: URL, base: URL, current: SeraTab) -> LinkAction`
  - `struct AppConfig { static let baseURL: URL; static let userAgentToken = "SeraApp/1" }`

- [ ] **Step 1: Make the project** in `~/sera/ios`, with `XcodeNewProject` (Xcode plugin) or File > New > Project:
  - product `Sera`
  - team: Evan's Personal Team (Phase 0a), with automatic signing
  - bundle ID `com.evankaplan.sera.dev`, and display name "Sera". Set it before the first build for a phone: the template's default (`com.evankaplan.Sera`) would otherwise be claimed by the free team and use up one of its 10 App IDs.
  - iOS 27.0, iPhone only, portrait only
  - Info.plist `ITSAppUsesNonExemptEncryption = NO`, so TestFlight doesn't ask about encryption on every upload
- [ ] **Step 2: Write the failing tests**

```swift
let base = URL(string: "https://sera-desk.fly.dev")!

@Test func tabPathsMatchTheWebTabBar() {
    #expect(SeraTab.allCases.map(\.path) == ["/", "/h/market", "/search", "/alerts", "/hubs"])
}
@Test func sameHostLinksLoadInPlace() {
    #expect(decide(URL(string: "https://sera-desk.fly.dev/t/GME")!, base: base, current: .today) == .load)
}
@Test func otherHostsOpenExternally() {
    #expect(decide(URL(string: "https://www.sec.gov/x")!, base: base, current: .today) == .openExternally)
}
@Test func alertsLinkFromAnotherTabSwitchesTab() {
    let u = URL(string: "https://sera-desk.fly.dev/alerts?kind=insider")!
    #expect(decide(u, base: base, current: .today) == .switchTab(.alerts, u))
}
@Test func mailAndTelOpenExternally() {
    #expect(decide(URL(string: "mailto:a@b.c")!, base: base, current: .more) == .openExternally)
}
```

- [ ] **Step 3: Run them to see them fail.** Run: `xcodebuild test -project ios/Sera.xcodeproj -scheme Sera -destination 'platform=iOS Simulator,name=iPhone 18 Pro Max'`. Expected: the build fails with `SeraTab` not found.
- [ ] **Step 4: Implement `SeraTab`, `LinkPolicy.decide` and `AppConfig`.**
  - `AppConfig.baseURL` reads the Info.plist key `SERA_BASE_URL`: `https://sera-desk.fly.dev` in Release, overridable in Debug.
  - Add `NSAppTransportSecurity > NSAllowsLocalNetworking = YES` for the local server.
- [ ] **Step 5: Run the tests.** Expected: all pass.
- [ ] **Step 6: Write `ios/README.md`.** Cover the Phase 0a and 0b prerequisites, the test command, the weekly reinstall (Task 3), and how to run on the simulator and on the phone. List the server pieces the app relies on: the `in-app` class from Task 1, and the routes from Task 5.
- [ ] **Step 7: Add a feature-notes line and commit.** `git commit -m "iPhone app: Xcode project, the five tabs and where links open"`

### Task 3: Web tabs, refresh, login, offline and outside links

**Files:**
- Create: `ios/Sera/WebTab.swift` (a `UIViewRepresentable` around `WKWebView`, plus a coordinator that is its `WKNavigationDelegate`)
- Create: `ios/Sera/TabRouter.swift`
- Create: `ios/Sera/OfflineView.swift`
- Modify: `ios/Sera/SeraApp.swift` (a `TabView` over `SeraTab.allCases`)
- Create: the app icon, a 1024 px PNG drawn from the rail's mark (`base.html:30`: the white check-line glyph) on the `--mark-top`/`--mark-bottom` graphite gradient with the `--mark-core` green (`sera.css:38`). `web/static/icons/` stops at 512 px, so it can't be the source.
- Create: `ios/scripts/install.sh` (build and install on Evan's iPhone in one command; the weekly free-team reinstall)
- Test: `ios/SeraTests/TabRouterTests.swift`

**Interfaces:**
- Consumes: `SeraTab`, `decide(_:base:current:)` and `AppConfig` (Task 2).
- Produces:

```swift
@MainActor @Observable final class TabRouter {
    var selected: SeraTab
    func open(_ url: URL)             // tab = SeraTab.owning(url) ?? selected; holds url as that tab's pending URL; selects it
    func take(for tab: SeraTab) -> URL?
    func loggedIn(from tab: SeraTab)  // asks every other tab still showing /login to reload
    var onLoggedIn: (() -> Void)?     // Task 6's registrar hooks in here
}
```

- [ ] **Step 1: Write the failing tests**

```swift
@MainActor @Test func openSelectsTheOwningTabAndHoldsTheURL() {
    let r = TabRouter(); let u = URL(string: "https://sera-desk.fly.dev/alerts")!
    r.open(u)
    #expect(r.selected == .alerts && r.take(for: .alerts) == u && r.take(for: .alerts) == nil)
}
@MainActor @Test func openWithoutOwnerStaysInTheCurrentTab() {
    let r = TabRouter(); r.selected = .market
    r.open(URL(string: "https://sera-desk.fly.dev/t/NVDA")!)
    #expect(r.selected == .market)
}
@MainActor @Test func loginOnOneTabReloadsTheOthers() { ... }  // tabs on /login get a reload request, the tab that logged in doesn't
```

- [ ] **Step 2: Run them to see them fail.** Use the same `xcodebuild test` command. Expected: `TabRouter` not found.
- [ ] **Step 3: Implement `TabRouter`.**
- [ ] **Step 4: Implement `WebTab`.**
  - **Setup:** one `WKWebView` per tab, made the first time the tab is selected and then kept. Use `WKWebsiteDataStore.default()`, `applicationNameForUserAgent = AppConfig.userAgentToken` and `allowsBackForwardNavigationGestures = true`.
  - **Refresh:** a `UIRefreshControl` on its scroll view calls `reload()`. A page left in the background for 10 minutes reloads on return (`scenePhase`), as `sera.js` does now.
  - **Links:** `decidePolicyFor` uses `decide`. `.openExternally` presents `SFSafariViewController` (`UIApplication.open` for non-http schemes), and `.switchTab` calls `router.open`.
  - **Login:** when a navigation finishes on a path that isn't `/login` and the previous one was `/login`, call `router.loggedIn(from:)`.
  - **Alerts:** each time the Alerts tab is selected, reload it. Its list and the seen marks only update on a load (`pages/alerts.py:38`).
  - **Re-tapping the selected tab** scrolls to top, then goes back to the tab's root path.
- [ ] **Step 5: Implement `OfflineView`** for `didFailProvisionalNavigation` with `NSURLErrorNotConnectedToInternet` or `NSURLErrorTimedOut`. Copy: title "Can't connect", body "Check the connection, then try again.", button "Try again".
- [ ] **Step 6: Run the tests.** Expected: all pass.
- [ ] **Step 6b: Write `ios/scripts/install.sh`.** A free-team install stops opening after 7 days, and the phone's registration to the free team lapses on the same clock. Reinstalling over the old app keeps its data, so the login survives. The script:
  - **finds the phone** with `xcrun devicectl list devices --json-output <tmpfile>` (Apple says to read the JSON, not the printed table): the one paired iPhone, or the name in `SERA_DEVICE` if there are several. It reads the phone's hardware UDID for the build and its device identifier for the install.
  - **checks it's unlocked** with `xcrun devicectl device info lockState --device <id>`. If it's locked, it prints "Unlock the phone, then run this again." and stops; Apple says devicectl needs an unlocked phone.
  - **builds for that phone**, not a generic device, so a lapsed registration is renewed:

```bash
xcodebuild -project ios/Sera.xcodeproj -scheme Sera -configuration Debug \
  -destination "id=$UDID" -derivedDataPath ios/build \
  -allowProvisioningUpdates -allowProvisioningDeviceRegistration \
  SERA_BASE_URL=https://sera-desk.fly.dev build
```

  - The `SERA_BASE_URL` override is there so the phone always gets the live box, even if a local address was left in the Debug settings (Step 7).
  - **installs** with `xcrun devicectl device install app --device <id> ios/build/Build/Products/Debug-iphoneos/Sera.app`.
  - **prints one line:** `Installed. Opens until <date>.`, with the date read from the profile it actually used (`security cms -D -i ios/build/Build/Products/Debug-iphoneos/Sera.app/embedded.mobileprovision | plutil -extract ExpirationDate raw -`). That stays right after Task 6 moves to the paid team, whose profiles last much longer. Otherwise it prints the reason: no phone found, the phone isn't paired (pair it again in Device Hub, which every iOS update needs), the phone isn't on this Wi-Fi, or signing failed.
  - Check: run it twice. The second run reinstalls without a cable (phone on the same Wi-Fi), and the app opens still logged in.
- [ ] **Step 7: Check it by hand on the simulator.**
  - First against a local server: `SERA_URL= SERA_PASS=test uv run sera serve`, with `SERA_BASE_URL=http://127.0.0.1:8080` set in the Sera scheme's Run environment or an uncommitted `ios/Local.xcconfig` (in `.gitignore`), never in the committed project. Stop that server when done.
  - Then against the live box.
  - Check:
    - [ ] no web tab bar under the native one, and the last row clears the tab bar
    - [ ] the pairing code logs in once, and the other tabs follow
    - [ ] pull-to-refresh and swipe-back work
    - [ ] an SEC link opens in the Safari view
    - [ ] a chart readout still works on a drag
    - [ ] light and dark both look right
    - [ ] the Alerts tab shows a new alert after switching back to it
    - [ ] the offline view appears with the Mac's Wi-Fi off
    - [ ] in Safari's Web Inspector (Develop > Simulator), a hidden tab's `/api/live` stream closes
  - Take a Pro Max screenshot of each tab for the PR.
- [ ] **Step 8: Ship it.**
  - Add a feature-notes line, commit and open the PR.
  - Deploy the server half (Task 1) with `sera-deploy`.
  - **First install, from Xcode:** pick the phone as the run destination and click Run (Product > Run). That registers the phone to the free team. Every later install is `ios/scripts/install.sh`.
  - **Evan, once, on the phone:** the first time, iOS won't open an app from a free developer until you trust it. Go to Settings > General > VPN & Device Management, tap your Apple ID under Developer App, then Trust. The phone needs internet for this.
  - Run `ios/scripts/install.sh` once to check the weekly path works.
  - Commit message: `git commit -m "iPhone app: tabs of web pages with refresh, swipe back, login, offline view and outside links in Safari"`

**Phase 1 is done when** Evan has used the app instead of the Home Screen app for a few days. Until Phase 2, pushes still arrive through the Home Screen app, so keep its icon. Then he decides whether the app is worth $99 a year (Phase 0b). If not, the free app stays, reinstalled weekly, and the plan stops here.

---

## Phase 0b: Paid setup (before Phase 2; $99 a year)

Start this only once Evan has used the Phase 1 app for a while and wants to keep it. These steps need his Apple ID, payment or keys, so Claude can't do them.

- [ ] **Step 1: Enroll in the Apple Developer Program** at developer.apple.com/programs ($99 a year, individual), with the same Apple ID as Phase 0a. Approval usually takes up to 48 hours. Xcode then lists a second team next to the Personal Team, with its own 10-character Team ID.
- [ ] **Step 2: Make two APNs keys.**
  - Go to developer.apple.com > Certificates, IDs & Profiles > Keys > +.
  - Make one key for Apple Push Notifications service with environment **Sandbox**, and one with **Production**.
  - Download both `AuthKey_<KEYID>.p8` files (Apple lets you download each only once) and note both Key IDs.
  - Store copies in your password manager.
- [ ] **Step 3: Check for ntfy.** Run `fly secrets list -a sera-desk` (names only). If `SERA_NTFY_TOPIC` is listed, alerts also go to ntfy (`alerts.py:1130`). Decide whether to unset it once the app pushes, so alerts don't arrive twice by another route.
- [ ] **Step 4: Set the keys** with `ops/set-apns-key.sh`. This step happens during Phase 2: Task 4 writes the script, and Task 5's deploy waits for it. Run it twice, once per environment. It asks for the Key ID, the paid team's Team ID and the path to the `.p8`, checks that the file is a P-256 private key, and sets the Fly secrets. It never prints the key. Delete the `.p8` files from Downloads afterwards.

---

## Phase 2: Native push

### Task 4: The server sends APNs

**Files:**
- Create: `sera/apns.py`
- Create: `ops/set-apns-key.sh` (the same shape as `ops/set-massive-key.sh`: hidden prompts, checks the key, `fly secrets set`, never prints it)
- Modify: `sera/push.py` (`send_all`, `devices`, `missing_phone`, and the new `has_device`)
- Modify: `datasets/alerts.py:1111` and `datasets/morning.py:924` (use `push.has_device(con)`)
- Modify: `sera/pushcopy.py:94` (no change to the keys; `urgent` is read by `apns.payload`)
- Modify: `pyproject.toml` (move `httpx` into `dependencies` as `httpx[http2]>=0.27`, then `uv lock`)
- Test: `tests/test_apns.py`, with its own fixtures; no network, so monkeypatch the httpx client the way `test_push.py` monkeypatches `urllib`

**Interfaces:**
- Produces:
  - **Table:** `apns_devices(token TEXT PRIMARY KEY, env TEXT NOT NULL CHECK (env IN ('sandbox','production')), device TEXT, created_at TEXT NOT NULL, last_ok TEXT, last_error TEXT)`, created by `apns.SCHEMA` the way `push.SCHEMA` creates its tables.
  - **`apns.creds(env: str) -> tuple[str, str, str] | None`:** `(key_pem, key_id, team_id)` from `APNS_KEY_P8_<ENV>`, `APNS_KEY_ID_<ENV>` and `APNS_TEAM_ID` (`<ENV>` is `SANDBOX` or `PRODUCTION`). `None` when any of them is missing.
  - **`apns.TOPIC`:** `os.environ.get("APNS_TOPIC", "com.evankaplan.sera")`.
  - **`apns.token(key_pem: str, key_id: str, team_id: str, now: int) -> str`:** an ES256 JWT with header `{"alg":"ES256","kid":key_id}` and claims `{"iss":team_id,"iat":now}`, signed with `cryptography`. Cached per environment and made again after 50 minutes (Apple wants it refreshed at most every 20 minutes and at least every 60).
  - **`apns.payload(message: dict) -> dict`:** `{"aps": {"alert": {"title": t, "body": b}, "badge": n, "sound": "default", "thread-id": tag, "interruption-level": "time-sensitive"|"active"}, "url": url}`.
    - `time-sensitive` when `message["urgent"]` is true.
    - `badge` and `thread-id` are left out when the message has none.
  - **`apns.host(env: str) -> str`:** `https://api.sandbox.push.apple.com` or `https://api.push.apple.com`.
  - **`apns.send(client, con, device: dict, message: dict) -> str | None`:**
    - POSTs to `{host}/3/device/{token}` with the headers `authorization: bearer <jwt>`, `apns-topic`, `apns-push-type: alert`, `apns-priority: 10`, and `apns-collapse-id` (the tag cut to 64 bytes, only when there is a tag).
    - Returns `None` on 200, otherwise the error text (`"400 BadDeviceToken"`).
    - A 410 deletes the row and calls `push._note_removed`. Any other error keeps the row and sets `last_error`.
    - With no credentials for that device's environment it returns `"no APNs key for <env>"` and sends nothing.
  - **`push.has_device(con) -> bool`:** any `push_subs` row or any `apns_devices` row.
  - **`push.send_all(con, message) -> tuple[int, int]`:** keeps its signature, and counts both kinds of device.

- [ ] **Step 1: Write the failing tests**

```python
def test_token_verifies_with_the_public_key(): ...           # decode; verify ES256 with the key's public half; iss, iat, kid
def test_token_is_reused_for_50_minutes_then_remade(): ...    # same string at +49 min, a new one at +51
def test_payload_maps_title_body_badge_url_and_thread():
    p = apns.payload({"title": "GME", "body": "8-K filed", "url": "/t/GME", "tag": "k1", "badge": 3, "urgent": False})
    assert p == {"aps": {"alert": {"title": "GME", "body": "8-K filed"}, "badge": 3, "sound": "default",
                         "thread-id": "k1", "interruption-level": "active"}, "url": "/t/GME"}
def test_urgent_alerts_are_time_sensitive(): ...
def test_collapse_id_is_cut_to_64_bytes(): ...
def test_sandbox_device_goes_to_sandbox_host_with_the_sandbox_key(): ...  # URL host and the JWT's kid
def test_gone_token_410_deletes_the_row(): ...
def test_bad_device_token_keeps_the_row(): ...                # 400 BadDeviceToken: row kept, last_error = "400 BadDeviceToken"
def test_missing_key_for_an_env_sends_nothing_and_says_so(): ...
def test_send_all_reaches_web_and_apns_devices(): ...         # one push_subs row + one apns row -> (2, 0)
def test_alert_reaches_an_apns_only_phone(): ...              # no push_subs rows: the alert isn't held as "no device", send_all is called
def test_morning_brief_reaches_an_apns_only_phone(): ...
def test_missing_phone_is_none_with_an_apns_device(): ...
```

- [ ] **Step 2: Run them to see them fail.** Run: `uv run pytest tests/test_apns.py -q`. Expected: all fail, `sera.apns` not found.
- [ ] **Step 3: Implement `sera/apns.py`, and wire it in:**
  - `push.has_device` (used at `alerts.py:1111` and `morning.py:924`)
  - `push.send_all`: one `httpx.Client(http2=True, timeout=15)` per call, closed after it
  - `push.devices` and `push.missing_phone`
- [ ] **Step 4: Write `ops/set-apns-key.sh`.**
  - It asks which environment, the Key ID (10 characters), the Team ID (10 characters) and the path to the `.p8`.
  - It checks the file is a P-256 private key with `openssl pkey -noout`.
  - It runs `fly secrets set -a sera-desk APNS_TEAM_ID=… APNS_KEY_ID_<ENV>=… APNS_KEY_P8_<ENV>=-`, with the key from stdin so it never shows in the process list.
  - It prints only "Saved" or the reason it didn't.
- [ ] **Step 5: Run the tests, then the full suite.** Run: `uv run pytest -q`. Expected: all pass.
- [ ] **Step 6: Add a feature-notes line and commit.** `git commit -m "Push: Apple's push service for the iPhone app, beside Web Push"`

### Task 5: Registration, the unseen count and the settings page

**Files:**
- Modify: `sera/app.py` (next to the `/api/push/*` routes at lines 181-207)
- Modify: `sera/alertsview.py:591-597` (list APNs devices with the Web Push ones)
- Modify: `web/templates/alerts_settings.html:73-85` (APNs rows; the "No phone is paired" banners say "Open the Sera app on your iPhone" once an APNs device was ever registered)
- Modify: `web/static/pages/alerts.js:105-107` (Remove sends `DELETE /api/push/apns/{token}` for an APNs row), then bump `alerts.js?v=`
- Modify: `web/static/sera.js` `syncPush` (a 409 from `/api/push/subscribe` sets `sera-push-off`)
- Test: `tests/test_apns.py` (route tests, logged in by setting `auth.COOKIE` on its own client)

**Interfaces:**
- Consumes: `apns.SCHEMA`, `push.devices` and `push.has_device` (Task 4).
- Produces:
  - **`apns.register(con, token: str, env: str, device: str) -> int`:**
    - upserts the device
    - deletes older `apns_devices` rows with the same `device` name and `env` (a reinstall gets a new token)
    - deletes `push_subs` rows whose `device` starts with `iPhone (Home Screen app)`
    - returns how many Web Push rows it deleted
  - **`POST /api/push/apns`** with body `{"token": "<hex>", "env": "sandbox"|"production", "device": "<name>"}` → `{"ok": true, "replaced": n}`. It answers 400 `{"error": "not a device token"}` unless the token matches `^[0-9a-f]{64,200}$` and `env` is one of the two.
  - **`DELETE /api/push/apns/{token}`** → `{"ok": true}`.
  - **`GET /api/unseen`** → `{"unseen": n}`, the same count `send_all` puts in `badge`.
  - **`POST /api/push/subscribe`:** answers 409 `{"error": "the iPhone app takes notifications"}` for a device starting with `iPhone (Home Screen app)` while any `apns_devices` row exists.

- [ ] **Step 1: Write the failing tests**

```python
def test_register_replaces_home_screen_rows_only(client):
    # push_subs rows: "iPhone (Home Screen app) · 10/1/2026", "Mac · 10/1/2026"
    r = client.post("/api/push/apns", json={"token": "ab" * 32, "env": "production", "device": "iPhone"})
    assert r.json() == {"ok": True, "replaced": 1}   # the Mac row is still there
def test_reinstall_replaces_the_old_token(client): ...
def test_home_screen_subscribe_is_refused_while_the_app_is_paired(client): ...  # 409; the Mac still subscribes
def test_register_refuses_a_bad_token(client): ...      # "xyz", a wrong env, a missing token: 400
def test_register_needs_login(): ...                    # a client with no cookie: 401 JSON
def test_unseen_counts_unseen_alerts(client): ...
def test_settings_page_lists_the_iphone_app_with_remove(client): ...
def test_delete_route_removes_the_device(client): ...
```

- [ ] **Step 2: Run them to see them fail.**
- [ ] **Step 3: Implement** `register`, the routes, the 409, the settings-page rows and the JS changes. Bump `?v=`.
- [ ] **Step 4: Run the full suite.** Run: `uv run pytest -q`. Expected: all pass.
- [ ] **Step 5: Add a feature-notes line, commit, open the PR and deploy with `sera-deploy`.**
  - Before the deploy, `fly secrets list -a sera-desk` must show `APNS_TEAM_ID`, `APNS_KEY_ID_SANDBOX` and `APNS_KEY_P8_SANDBOX` (names only).
  - Commit message: `git commit -m "Push: the iPhone app registers its device, and the unseen count has its own route"`

### Task 6: The app registers, shows the badge and opens taps

**Files:**
- Create: `ios/Sera/PushRegistrar.swift`, `ios/Sera/AppDelegate.swift` (`@UIApplicationDelegateAdaptor`, `UNUserNotificationCenterDelegate`)
- Create: `ios/Sera/Sera.entitlements`:
  - `aps-environment` (Xcode sets `development` for Debug and `production` for TestFlight builds)
  - `com.apple.developer.usernotifications.time-sensitive`
- Modify: `ios/Sera.xcodeproj/project.pbxproj` (team and bundle ID, Step 0)
- Modify: `ios/Sera/SeraApp.swift`, `ios/Sera/WebTab.swift` (after each page load, refresh the unseen count)
- Test: `ios/SeraTests/PushRegistrarTests.swift`, `ios/SeraTests/TabRouterTests.swift`

**Interfaces:**
- Consumes: `POST /api/push/apns` and `GET /api/unseen` (Task 5); `TabRouter.open` and `TabRouter.onLoggedIn` (Task 3).
- Produces:

```swift
@MainActor final class PushRegistrar {
    enum State: Equatable { case idle, waitingForLogin, registered }
    private(set) var state: State
    init(post: @escaping (URLRequest) async throws -> Int)   // returns the HTTP status; injected so tests need no server
    static func body(token: Data, env: String, device: String) -> Data  // lowercase hex token, JSON as Task 5 expects
    func didReceive(token: Data) async   // a 401 sets .waitingForLogin
    func loggedIn() async                // resends when .waitingForLogin; wired to TabRouter.onLoggedIn
}
```

  - The session cookie comes from `WKWebsiteDataStore.default().httpCookieStore` (`serasession`) and is set on each `URLRequest`, because `URLSession` doesn't share the web view's cookies.
  - `env` is `"sandbox"` in Debug builds and `"production"` otherwise (`#if DEBUG`).

- [ ] **Step 0: Move the project to the paid team** (needs Phase 0b Step 1).
  - In the Sera target's Signing & Capabilities, set Team to the paid team and the bundle ID to `com.evankaplan.sera`. Add the Push Notifications and Time Sensitive Notifications capabilities; the free team can't add either.
  - Build and run `ios/scripts/install.sh`, then delete the old `com.evankaplan.sera.dev` app from the phone.
  - The new bundle ID gets a new app container, so the web views start logged out. Log in once with a pairing code.
  - Commit: `git commit -m "iPhone app: the paid team and the final bundle ID"`

- [ ] **Step 1: Write the failing tests**

```swift
@MainActor @Test func bodyIsHexTokenEnvAndDevice() throws {
    let b = PushRegistrar.body(token: Data([0xab, 0x01]), env: "sandbox", device: "iPhone")
    let j = try JSONSerialization.jsonObject(with: b) as! [String: String]
    #expect(j == ["token": "ab01", "env": "sandbox", "device": "iPhone"])
}
@MainActor @Test func registrationRetriesAfterUnauthorized() async { ... }  // 401 -> .waitingForLogin; loggedIn() -> sends again -> .registered
@MainActor @Test func coldLaunchURLIsHeldUntilTabsExist() {
    let r = TabRouter(); r.open(URL(string: "https://sera-desk.fly.dev/t/GME")!)   // before any WebTab
    #expect(r.take(for: r.selected) != nil)
}
```

- [ ] **Step 2: Run them to see them fail.**
- [ ] **Step 3: Implement.**
  - **Permission:** ask for alerts, badges and sounds after the first logged-in page load, never on the login page. Then call `UIApplication.registerForRemoteNotifications()`.
  - **Taps:** read `url` from the payload, resolve it against `AppConfig.baseURL` and call `router.open`.
  - **While the app is open:** show notifications as banners.
  - **Badge:** set the Alerts tab's `.badge` and `UNUserNotificationCenter.setBadgeCount` from `/api/unseen` on launch, on return to the foreground and after each page load.
- [ ] **Step 4: Run the tests.** Expected: all pass.
- [ ] **Step 5: Check it on Evan's iPhone.** Pushes from a real server don't reach the simulator.
  1. Install with `ios/scripts/install.sh` (a Debug build, so sandbox).
  2. Delete the Home Screen web app's icon.
  3. Press "Send a test" on Alerts > Notifications, then check:
     - [ ] exactly one banner arrives
     - [ ] the badge shows the unseen count
     - [ ] a tap opens `/alerts` in the Alerts tab
     - [ ] the settings page lists "iPhone" and no Home Screen row
  4. Wait for one real alert and check it arrives once.
- [ ] **Step 6: Add a feature-notes line, commit and open the PR.** `git commit -m "iPhone app: native notifications, the unseen badge and taps that open the alert"`

### Task 7: TestFlight

**Files:**
- Modify: `ios/README.md` (how to archive and upload)
- Modify: `docs/feature-notes.md`

- [ ] **Step 1: Check the production key is on the box.** `fly secrets list -a sera-desk` shows `APNS_KEY_ID_PRODUCTION` and `APNS_KEY_P8_PRODUCTION`. If not, Evan runs `ops/set-apns-key.sh` for production.
- [ ] **Step 2: Archive and upload.** In Xcode: Product > Archive, then Distribute App > TestFlight Internal Only. The first time, Xcode makes the App Store Connect record; name it "Sera" with bundle ID `com.evankaplan.sera`.
- [ ] **Step 3: Add Evan as a tester.** In App Store Connect > TestFlight, add him as an internal tester, and install the TestFlight app on the iPhone.
- [ ] **Step 4: Install from TestFlight and test the production host.**
  - Press "Send a test" again. This build registers as `production`, so this checks the production host.
  - Remove the Xcode build's sandbox row on the settings page.
- [ ] **Step 5: Record it.** Write the date in `ios/README.md` and a feature-notes line. If ntfy was kept (Phase 0b Step 3), decide now whether to unset `SERA_NTFY_TOPIC`.

**Phase 2 is done when** a week of real alerts has arrived through the app, each once, with the right badge.

---

## Phase 3: Native features (candidates; each gets its own short plan)

Only start these after Phase 2 has pushed reliably for a week. Pick by what Evan reaches for.

- **Lock Screen and Home Screen widget:** unseen alerts and the watchlist's top movers.
  - Needs one small JSON route.
  - WidgetKit refreshes on a timeline (about every 15 to 30 minutes), so the widget shows the time of its numbers.
- **App Intents:** "Open GME in Sera" from Siri, Spotlight and the Action button. It opens `/t/{SYMBOL}` through `TabRouter.open`.
- **Share into Sera:** a ticker or link shared from another app opens its Sera page.

## Phase 4: Native screens (candidates; one at a time)

Only start one of these when a web page measurably fails in the app (touch handling, scrolling, load time). Each reads JSON that already exists or gets a new route, and the server stays the only source of numbers. Landscape comes back here, if a native screen needs it.

- **Ticker header with live quotes:** `/api/live` is already a server-sent event stream.
- **Charts:** Swift Charts for the chart kit's line and bar charts, if web touch readouts feel worse than native.
- **Search:** `/api/command` already returns grouped results.

## Execution

Phases 0a and 0b are mostly Evan's. Phase 1 (Tasks 1 to 3) is free and stands on its own. Phase 2 is Tasks 4 to 7. Tasks 4 and 5 can be written and tested while Phase 1 is in use, but they're deployed only after Phase 0b, since Task 5's deploy needs the APNs secrets. Tasks 4 and 5 (server) don't depend on Tasks 2 and 3 (app), so they can run in parallel.

Recommended: subagent-driven. The app and server tasks meet at exact interfaces (the user agent token, the `in-app` class, the registration JSON), and a mistake in push means missed or doubled alerts.
