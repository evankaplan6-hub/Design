// Smart Check Clean buttons: the final design (B3 + M2), drawn with real SwiftUI offscreen.
// Run: ./render.sh [outdir]. It compiles this file together with Vitals' own files at a pinned
// commit (read with `git show`, never checked out), so every state, plan, size and sentence below
// is the app's own: CleanPreviewStates, CleanPolicy, CleanWords, CleanError, SmartSizer, Theme,
// Module, glassButton (its snapshot style), StatusGlyph, Spinner (an hourglass in a snapshot),
// SnapshotCircleButton and IconCache.
// Faked here: the panel's title bar and tab control (PanelChrome), the stage rows' figures, the
// NSAlert (AlertStandIn), "Checked at 9:49 AM", "Rebuilds itself 35.7 GB" and the tally squares
// (left out). Glass, spinners and scroll views draw as the app's own snapshot stand-ins.
import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Words the design adds. Move these into CleanWords when porting; the views never spell words.

extension CleanWords {
    static let cleanUpTitle = "Clean up"
    static func itemCount(_ n: Int) -> String { n == 1 ? "1 item" : "\(n) items" }
    static let staysFree = "Stays free"
    static let comesBackHeading = "Comes back as you work"
    static let putBackButton = "Put Back"
    static let back = "Back"
    /// Before a clean: "up to 10.2 GB". The same words CleanPolicy uses in its confirmations.
    static func upTo(_ bytes: UInt64) -> String { "up to \(SmartSizer.format(bytes))" }
    /// Joins a caption's parts: "up to 10.2 GB · Old package downloads".
    static func caption(_ parts: [String]) -> String { parts.joined(separator: " · ") }
    /// A tool clean can take up to 3 minutes and reports no progress.
    static let cleaningTool = "Cleaning. This can take a few minutes."
    static let cleaningTrash = "Moving to the Trash"
    /// The same words SystemActions already speaks ("Cleaning npm cache", "Put back Cursor snapshots").
    static func cleaning(_ title: String) -> String { "Cleaning \(title)" }
    static func puttingBack(_ title: String) -> String { "Putting back \(title)" }
    static func putBackLabel(_ title: String) -> String { "Put back \(title)" }
    static func oneAtATime(_ title: String) -> String { "One at a time. Wait for \(title) to finish." }
    /// Measured totals only; nil when nothing has been measured yet.
    static func totals(freed: UInt64, inTrash: UInt64) -> String? {
        var parts: [String] = []
        if freed > 0 { parts.append("Freed \(SmartSizer.format(freed))") }
        if inTrash > 0 { parts.append("\(SmartSizer.format(inTrash)) in the Trash") }
        return parts.isEmpty ? nil : caption(parts)
    }
}

// MARK: - The Nov 14 scan's cleanable findings (titles, notes and sizes as the scanners write them)

@MainActor
enum Scan {
    static let home = CleanPreviewStates.home
    static func f(_ id: String, _ title: String, _ bytes: UInt64, _ note: String?, stage: SmartStage = .storage,
                  kind: SmartFinding.Kind = .rebuilds) -> SmartFinding {
        SmartFinding(id: id, stage: stage, title: title, bytes: bytes, note: note, kind: kind, cleanupHint: nil)
    }
    static let cursor = f("cursor-snapshots", "Cursor snapshots", 10_843_963_392, "Edit checkpoints from past AI sessions.")
    static let uv = f("uv", "Python download cache (uv)", 10_165_321_728, "Old package downloads.")
    static let npm = f("npm", "npm cache", 3_312_345_088, nil)
    static let pnpm = f("pnpm", "pnpm store", 849_842_176, nil)
    static let codex = f("codex-codex-runtime-install-7f3a", "Codex install leftover", 339_738_624,
                         "A half-finished install; the live runtime is codex-primary-runtime.", kind: .win)
    static let derived = f("derived-data", "Xcode build files", 202_539_008, "Rebuilt automatically on the next build.")
    static let nvidia = f("leftover:NVIDIA", "Possible leftovers from NVIDIA", 146_051_072,
                          "Possible: the app seems to be gone. Check before removing.", stage: .apps, kind: .win)
    static let caches = f("app-caches", "App caches", 5_354_717_184, "Apps rebuild these as you use them.")

    /// What `cleanablePlans(in:)` returns: offered findings, biggest first.
    static let cleanable: [SmartFinding] = [cursor, uv, npm, pnpm, codex, derived, nvidia]
        .filter { plan($0) != nil }
        .sorted { (plan($0)?.expectedBytes ?? 0) > (plan($1)?.expectedBytes ?? 0) }
    static let wins: [SmartFinding] = [codex, nvidia]   // SmartResult.wins: lasting, 100 MB or more
    static let byID = Dictionary(uniqueKeysWithValues: (cleanable + [caches]).map { ($0.id, $0) })

    static func plan(_ f: SmartFinding) -> CleanPlan? { CleanPolicy.offer(for: f, home: home).plan }

    static func trashed(_ f: SmartFinding) -> CleanOutcome {
        CleanOutcome(id: f.id, method: .moveToTrash, bytesBefore: f.bytes, bytesAfter: 0, freedBytes: 0,
                     movedToTrashBytes: f.bytes, trashed: [TrashedItem(original: plan(f)!.path, inTrash: "/Users/evankaplan/.Trash/x")],
                     finishedAt: Date(), message: CleanWords.outcomeMessage(method: .moveToTrash, freed: 0, trashed: f.bytes))
    }
    /// pnpm's made-up "freed a little" outcome, as in CleanPreviewStates.
    static func pruned(_ f: SmartFinding, freed: UInt64) -> CleanOutcome {
        CleanOutcome(id: f.id, method: plan(f)!.method, bytesBefore: f.bytes, bytesAfter: f.bytes! - freed, freedBytes: freed,
                     movedToTrashBytes: 0, trashed: [], finishedAt: Date(),
                     message: CleanWords.outcomeMessage(method: plan(f)!.method, freed: freed, trashed: 0))
    }

    static func fresh(_ f: SmartFinding) -> CleanState { .ready(plan(f)!) }

    /// Mid-session: Cursor is open, pnpm freed 120 MB, NVIDIA is in the Trash, npm is cleaning.
    static func session(_ f: SmartFinding) -> CleanState {
        let p = plan(f)!
        switch f.id {
        case cursor.id: return .blocked(p, apps: ["Cursor"])
        case pnpm.id: return .done(p, pruned(f, freed: 120_000_000), canPutBack: false)
        case nvidia.id: return .done(p, trashed(f), canPutBack: true)
        case npm.id: return .cleaning(p)
        default: return .waiting(p)
        }
    }
    /// Freed: `cleaner.totalFreed`. In the Trash: summed from rows that can still be put back,
    /// because `cleaner.totalMovedToTrash` never drops when Evan empties the Trash.
    static func totals(_ rows: [(finding: SmartFinding, state: CleanState)], freed: UInt64) -> (freed: UInt64, inTrash: UInt64) {
        let inTrash = rows.compactMap { r -> UInt64? in
            if case .done(_, let o, true) = r.state { return o.movedToTrashBytes } else { return nil }
        }.reduce(0, +)
        return (freed, inTrash)
    }
}

// MARK: - One row: icon, title, caption, action, Copy for Claude

/// The app's icon when an app blocks the clean (its blocker's bundle), otherwise a plain folder.
/// Uses the app's IconCache; reads no file inside the folder.
struct CleanIcon: View {
    var plan: CleanPlan?
    var body: some View {
        Image(nsImage: image).resizable().interpolation(.high).frame(width: 28, height: 28)
            .accessibilityHidden(true)
    }
    private var image: NSImage {
        if let id = plan?.blockers.first?.bundleIDs.first,
           let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) {
            return IconCache.icon(for: url.path)
        }
        return NSWorkspace.shared.icon(for: .folder)
    }
}

struct CleanRow: View {
    var finding: SmartFinding
    var state: CleanState
    /// `cleaner.busy`: Put Back waits too (the controller ignores it while busy).
    var busy = false
    /// The action column is a fixed width so captions wrap the same in every state.
    static let actionWidth: CGFloat = 124

    var body: some View {
        HStack(spacing: 10) {
            CleanIcon(plan: state.plan)
            VStack(alignment: .leading, spacing: 1) {
                Text(finding.title).font(.callout).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                caption
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            action.frame(width: Self.actionWidth, alignment: .trailing)
            SnapshotCircleButton(systemName: "doc.on.clipboard", diameter: 26)   // CopyForClaudeButton(iconOnly:) in the app
        }
        .frame(minHeight: 44)
    }

    /// "up to 10.8 GB · Edit checkpoints from past AI sessions", like SmartWinRow.
    private var upTo: String {
        var parts: [String] = []
        if let b = state.plan?.expectedBytes ?? finding.bytes { parts.append(CleanWords.upTo(b)) }
        if let note = finding.note {
            parts.append((note.components(separatedBy: CharacterSet(charactersIn: ";.")).first ?? note)
                .trimmingCharacters(in: .whitespaces))
        }
        return CleanWords.caption(parts)
    }

    @ViewBuilder private var caption: some View {
        switch state {
        case .ready, .waiting, .putBack:
            quiet(upTo)
        case .blocked(let p, let apps):
            // The quit sentence replaces the note, so the row stays short.
            quiet(CleanWords.caption((p.expectedBytes.map { [CleanWords.upTo($0)] } ?? []) + [CleanError.blocked(apps: apps).message]))
        case .cleaning(let p):
            quiet(p.method == .moveToTrash ? CleanWords.cleaningTrash : CleanWords.cleaningTool)
        case .done(_, let o, _), .puttingBack(_, let o):
            said(o.message)
        case .failed(_, let m), .putBackFailed(_, _, let m):
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                StatusGlyph(status: .warning, size: 10)
                said(m)
            }
        case .notOffered:
            quiet(upTo)   // a Biggest wins row with no button keeps today's caption
        }
    }

    private func quiet(_ s: String) -> some View {
        Text(s).font(.caption).foregroundStyle(Theme.secondaryText).lineLimit(4).fixedSize(horizontal: false, vertical: true)
    }
    /// What happened is the news of the row, so it is primary, never green.
    private func said(_ s: String) -> some View {
        Text(s).font(.caption).foregroundStyle(.primary).lineLimit(4).fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private var action: some View {
        switch state {
        case .ready(let p), .putBack(let p), .failed(let p, _):
            Button(p.buttonTitle) {}.glassButton()
        case .blocked(let p, _), .waiting(let p):
            Button(p.buttonTitle) {}.glassButton().disabled(true)
        case .cleaning(let p):
            Spinner().accessibilityLabel(CleanWords.cleaning(p.findingTitle))
        case .puttingBack(let p, _):
            Spinner().accessibilityLabel(CleanWords.puttingBack(p.findingTitle))
        case .done(let p, _, true), .putBackFailed(let p, _, _):
            Button(CleanWords.putBackButton) {}.glassButton().disabled(busy)
                .accessibilityLabel(CleanWords.putBackLabel(p.findingTitle))
        case .done(_, _, false), .notOffered:
            Color.clear.frame(width: 1, height: 1)
        }
    }
}

// MARK: - The Clean up screen (one level down from the result, inside the same Smart Check module)

struct CleanUpScreen: View {
    var rows: [(finding: SmartFinding, state: CleanState)]
    var totals: (freed: UInt64, inTrash: UInt64) = (0, 0)

    var body: some View {
        Module(padding: 0, alignment: .top) {
            VStack(spacing: 0) {
                ZStack {
                    HStack {
                        SnapshotCircleButton(systemName: "chevron.left", diameter: 26)   // glassButton, circle
                            .accessibilityLabel(CleanWords.back)
                        Spacer()
                    }
                    Text(CleanWords.cleanUpTitle).font(.headline).accessibilityAddTraits(.isHeader)   // focus lands here on open
                }
                .padding(.horizontal, 12).padding(.vertical, 10)
                Divider()
                ScrollIfLive {
                    VStack(alignment: .leading, spacing: 4) {
                        if let busy = busyTitle {
                            Text(CleanWords.oneAtATime(busy)).font(.footnote).foregroundStyle(Theme.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        group(CleanWords.staysFree, staysFigure, rows.filter { $0.state.plan?.comesBack == false })
                        group(CleanWords.comesBackHeading, nil, rows.filter { $0.state.plan?.comesBack == true })
                            .padding(.top, 6)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .frame(minHeight: 0, maxHeight: .infinity, alignment: .top)
                .clipped()
                if let line = CleanWords.totals(freed: totals.freed, inTrash: totals.inTrash) {
                    Divider()
                    HStack {
                        Text(line).font(.callout.monospacedDigit()).foregroundStyle(Theme.secondaryText)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12).frame(height: 40)
                }
            }
        }
    }

    private var busyTitle: String? {
        rows.first { if case .cleaning = $0.state { true } else if case .puttingBack = $0.state { true } else { false } }?.finding.title
    }

    /// "up to" over the lasting rows still on offer, so it never contradicts a finished row.
    private var staysFigure: String? {
        let open = rows.filter { $0.state.plan?.comesBack == false }.filter {
            switch $0.state { case .done, .puttingBack, .putBackFailed: false; default: true }
        }
        let bytes = open.compactMap { $0.state.plan?.expectedBytes }.reduce(0, +)
        return bytes > 0 ? CleanWords.upTo(bytes) : nil
    }

    @ViewBuilder private func group(_ title: String, _ figure: String?, _ items: [(finding: SmartFinding, state: CleanState)]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title).font(.callout.weight(.semibold)).foregroundStyle(Theme.secondaryText)
                    Spacer(minLength: 8)
                    if let figure { Text(figure).font(.callout.monospacedDigit()).foregroundStyle(Theme.secondaryText) }
                }
                .frame(height: 24)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
                ForEach(items, id: \.finding.id) { CleanRow(finding: $0.finding, state: $0.state, busy: busyTitle != nil) }
            }
        }
    }
}

// MARK: - The result, with the way in

struct ResultScreen: View {
    var winStates: [CleanState]
    /// The row that is cleaning or putting back, if any.
    var busyState: CleanState? = nil
    var totals: (freed: UInt64, inTrash: UInt64) = (0, 0)
    var count = Scan.cleanable.count

    var body: some View {
        Module(alignment: .top) {
            VStack(spacing: 12) {
                ScrollIfLive {
                    VStack(alignment: .leading, spacing: 12) {
                        header
                        stages
                        also
                        Divider().padding(.vertical, 2)
                        entry
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Biggest wins").font(.callout.weight(.semibold)).foregroundStyle(Theme.secondaryText)
                            ForEach(Array(zip(Scan.wins, winStates)), id: \.0.id) { CleanRow(finding: $0.0, state: $0.1, busy: busyState != nil) }
                        }
                        HStack {
                            Text("Rebuilds itself").font(.callout).foregroundStyle(Theme.secondaryText)
                            Spacer(minLength: 8)
                            Text("35.7 GB").font(.callout.monospacedDigit()).foregroundStyle(Theme.secondaryText)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                .frame(minHeight: 0, maxHeight: .infinity, alignment: .top)
                .clipped()
                HStack(spacing: 8) {
                    Spacer(minLength: 0)
                    Button("Check again") {}.glassButton()
                    Button("Done") {}.glassButton()
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Circle().fill(Theme.color(for: OverallHealth.good)).frame(width: 8, height: 8)
                Text(OverallHealth.good.label(hidden: 1)).font(.system(.title3, design: .rounded).weight(.semibold))
            }
            Text((["Checked at 9:49 AM"] + [CleanWords.totals(freed: totals.freed, inTrash: totals.inTrash)].compactMap { $0 })
                    .joined(separator: " · "))   // the header's own line; port with CleanWords.caption
                .font(.footnote.monospacedDigit()).foregroundStyle(Theme.secondaryText)
        }
        .padding(.bottom, 4)
        // The app's header is one VoiceOver element (Spoken.smartCheckFinished); add the totals to it.
    }

    private var stages: some View {
        VStack(spacing: 0) {
            stage(.info, "Storage", "Up to 486 MB you could clear")
            stage(.ok, "Protection", "3 of 3 protections on")
            stage(.ok, "Performance", "Memory, heat, battery and disk are fine")
            stage(.info, "Startup items", "1 item starts on its own")
            stage(.info, "Apps", "1 possible leftover")
        }
    }
    private func stage(_ s: CheckStatus, _ title: String, _ summary: String) -> some View {
        HStack(spacing: 10) {
            StatusGlyph(status: s, size: 16).frame(width: 18, height: 18)
            Text(title).font(.callout)
            Spacer(minLength: 8)
            Text(summary).font(.callout).foregroundStyle(Theme.secondaryText).lineLimit(1)
        }
        .frame(height: 28)
    }
    private var also: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Also needs a look").font(.callout.weight(.semibold)).foregroundStyle(Theme.secondaryText).padding(.bottom, 2)
            HStack(spacing: 10) {
                StatusGlyph(status: .problem, size: 16).frame(width: 18, height: 18).opacity(0.45)
                Text("Backups").font(.callout)
                Spacer(minLength: 8)
                Text("Hidden").font(.callout).foregroundStyle(Theme.secondaryText)
            }
            .frame(height: 28)
        }
    }

    /// The one way into the full list. While something runs it says what, so reopening the panel
    /// mid-clean shows it.
    private var entry: some View {
        HStack(spacing: 8) {
            Text(CleanWords.cleanUpTitle).font(.callout)
            Spacer(minLength: 8)
            if busyState != nil { Spinner().accessibilityHidden(true) }
            Text(entryValue).font(.callout).foregroundStyle(Theme.secondaryText).lineLimit(1)
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Theme.secondaryText)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 12).frame(minHeight: 40)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.fill.tertiary))
        // A real Button in the app; VoiceOver reads "Clean up, 7 items".
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(CleanWords.cleanUpTitle)
        .accessibilityValue(entryValue)
        .accessibilityAddTraits(.isButton)
    }

    private var entryValue: String {
        switch busyState {
        case .cleaning(let p)?: CleanWords.cleaning(p.findingTitle)
        case .puttingBack(let p, _)?: CleanWords.puttingBack(p.findingTitle)
        default: CleanWords.itemCount(count)
        }
    }
}

// MARK: - Stand-ins: the panel around the card, and NSAlert

struct PanelChrome<Content: View>: View {
    var height: CGFloat = Theme.height
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: Theme.gap + 2) {
            HStack(spacing: 8) {
                Text("MacBook Pro").font(.system(size: 17, weight: .semibold))
                Spacer()
                HStack(spacing: 5) { Circle().fill(Color.gray).frame(width: 7, height: 7); Text("1 hidden").font(.callout) }
                    .padding(.horizontal, 10).padding(.vertical, 4).background(Capsule().fill(.fill.tertiary))
                SnapshotCircleButton(systemName: "arrow.clockwise", diameter: 26)
                SnapshotCircleButton(systemName: "gearshape", diameter: 26)
            }
            .padding(.horizontal, 4).padding(.top, 4)
            HStack(spacing: 0) {
                ForEach(["Overview", "Chip", "Memory", "Processes", "Battery", "Health"], id: \.self) { t in
                    Text(t).font(.callout.weight(t == "Overview" ? .semibold : .regular))
                        .frame(maxWidth: .infinity).frame(height: 22)
                        .background(RoundedRectangle(cornerRadius: 7).fill(t == "Overview" ? AnyShapeStyle(.background) : AnyShapeStyle(.clear)))
                }
            }
            .padding(2).background(RoundedRectangle(cornerRadius: 9).fill(.fill.tertiary))
            content
        }
        .padding(Theme.outerPadding)
        .frame(width: Theme.width, height: height, alignment: .top)
    }
}

/// NSAlert as SystemActions.clean builds it (.warning style): the plan's own title, message and
/// button, then Cancel as the default (Return). The real alert is a separate window with Vitals' icon.
struct AlertStandIn: View {
    var plan: CleanPlan
    var body: some View {
        VStack(spacing: 10) {
            Image(nsImage: NSWorkspace.shared.icon(for: .applicationBundle)).resizable().frame(width: 52, height: 52)
                .overlay(alignment: .bottomTrailing) {   // .warning style badge
                    Image(systemName: "exclamationmark.triangle.fill").symbolRenderingMode(.palette)
                        .foregroundStyle(Color.black.opacity(0.82), Color.yellow).font(.system(size: 20)).offset(x: 6, y: 4)
                }
            Text(plan.confirmTitle).font(.body.weight(.bold)).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            Text(plan.confirmMessage).font(.callout).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 6) {
                // Added first, so drawn first; Return is moved to Cancel, which makes Cancel the blue default.
                Text(plan.confirmButton).font(.body).frame(maxWidth: .infinity).frame(height: 28)
                    .background(Capsule().fill(.fill.tertiary))
                Text("Cancel").font(.body).foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 28)
                    .background(Capsule().fill(Color.accentColor))
            }
            .padding(.top, 4)
        }
        .padding(18)
        .frame(width: 270)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color(nsColor: .windowBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.primary.opacity(0.12)))
        .shadow(color: .black.opacity(0.35), radius: 24, y: 10)
    }
}

// MARK: - Every state, from CleanPreviewStates.all

struct StateBoard: View {
    var body: some View {
        let all = CleanPreviewStates.all
        let half = (all.count + 1) / 2
        VStack(alignment: .leading, spacing: 12) {
            Text("Every CleanState, from CleanPreviewStates.all. Sizes are the Nov 14 scan's; outcomes are made up.")
                .font(.callout).foregroundStyle(Theme.secondaryText)
            HStack(alignment: .top, spacing: 16) {
                column(Array(all[..<half]))
                column(Array(all[half...]))
            }
        }
        .padding(16)
    }
    private func column(_ items: [(name: String, finding: SmartFinding, state: CleanState)]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(items, id: \.name) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name).font(.caption.monospaced()).foregroundStyle(Theme.secondaryText)
                    Module {
                        if case .notOffered = item.state {
                            VStack(alignment: .leading, spacing: 4) {
                                CleanRow(finding: Scan.byID[item.finding.id] ?? item.finding, state: item.state)
                                Text("No button, and not in Clean up (cleanablePlans leaves it out). App caches refill, so it is never a win either; a win with no button, like Ollama, keeps this caption in Biggest wins.")
                                    .font(.caption2).foregroundStyle(.tertiary)
                            }
                        } else {
                            CleanRow(finding: Scan.byID[item.finding.id] ?? item.finding, state: item.state)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(width: Theme.width - 2 * Theme.outerPadding)
    }
}

// MARK: - Render

@MainActor
func screens() -> [(String, AnyView)] {
    let fresh = Scan.cleanable.map { ($0, Scan.fresh($0)) }
    let session = Scan.cleanable.map { (finding: $0, state: Scan.session($0)) }
    let t = Scan.totals(session, freed: 120_000_000)
    let npmCleaning = Scan.session(Scan.npm)
    return [
        ("1-result", AnyView(PanelChrome { ResultScreen(winStates: Scan.wins.map(Scan.fresh)) })),
        ("1b-result-scrolled", AnyView(PanelChrome(height: 760) { ResultScreen(winStates: Scan.wins.map(Scan.fresh)) })),
        ("2-confirm-clean", AnyView(PanelChrome { CleanUpScreen(rows: fresh) }
            .overlay { Color.black.opacity(0.18); AlertStandIn(plan: Scan.plan(Scan.uv)!) })),
        ("3-confirm-trash", AnyView(PanelChrome { ResultScreen(winStates: Scan.wins.map(Scan.fresh)) }
            .overlay { Color.black.opacity(0.18); AlertStandIn(plan: Scan.plan(Scan.nvidia)!) })),
        ("4-cleanup", AnyView(PanelChrome { CleanUpScreen(rows: fresh) })),
        ("5-cleanup-session", AnyView(PanelChrome { CleanUpScreen(rows: session, totals: t) })),
        ("6-result-reopened", AnyView(PanelChrome {
            ResultScreen(winStates: Scan.wins.map(Scan.session), busyState: npmCleaning, totals: t)
        })),
        ("7-states", AnyView(StateBoard())),
    ]
}

@main struct Render {
    @MainActor static func main() {
        let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "out"
        try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
        for (name, view) in screens() {
            for scheme in [ColorScheme.light, .dark] {
                let bg = scheme == .dark ? Color(red: 0.137, green: 0.137, blue: 0.145) : Color(red: 0.925, green: 0.925, blue: 0.933)
                let content = view.background(bg).environment(\.colorScheme, scheme).environment(\.isSnapshot, true)
                NSApplication.shared.appearance = NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)
                var png: Data?
                (NSApplication.shared.appearance ?? NSAppearance.currentDrawing()).performAsCurrentDrawingAppearance {
                    let r = ImageRenderer(content: content); r.scale = 2; r.isOpaque = true
                    if let cg = r.cgImage, let space = CGColorSpace(name: CGColorSpace.sRGB),
                       let ctx = CGContext(data: nil, width: cg.width, height: cg.height, bitsPerComponent: 8, bytesPerRow: 0,
                                           space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
                        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
                        if let out = ctx.makeImage() { png = NSBitmapImageRep(cgImage: out).representation(using: .png, properties: [:]) }
                    }
                }
                guard let png else { print("fail \(name)"); continue }
                let path = "\(outDir)/\(name)-\(scheme == .dark ? "dark" : "light").png"
                try? png.write(to: URL(fileURLWithPath: path)); print("wrote \(path)")
            }
        }
    }
}
