// Clean buttons: three directions, drawn with real SwiftUI (ImageRenderer), offscreen.
// Run: swiftc -parse-as-library -target arm64-apple-macosx26.0 -o /tmp/cbd Directions.swift && /tmp/cbd out
// Sizes are the Nov 14 scan's real ones. Outcomes are made up, including the disappointing one.
// Glass, spinners and NSAlert can't be drawn by ImageRenderer: they get flat stand-ins.
import SwiftUI
import AppKit

let secondary = Color.primary.opacity(0.72)

// MARK: - Data (words from CleanPolicy / CleanWords on feat/smart-check-clean-actions)

enum RowState {
    case ready, blocked(String), waiting, cleaning, done(String, putBack: Bool), failed(String)
}

struct Item: Identifiable {
    let id: String
    let title: String
    let bytes: String
    let comesBack: Bool
    let button: String
    var note: String? = nil
    var state: RowState = .ready
}

let base: [Item] = [
    Item(id: "cursor", title: "Cursor snapshots", bytes: "10.8 GB", comesBack: true, button: "Move to Trash"),
    Item(id: "uv", title: "Python download cache (uv)", bytes: "10.2 GB", comesBack: true, button: "Clean"),
    Item(id: "npm", title: "npm cache", bytes: "3.3 GB", comesBack: true, button: "Clean"),
    Item(id: "pnpm", title: "pnpm store", bytes: "850 MB", comesBack: true, button: "Clean"),
    Item(id: "codex", title: "Codex install leftover", bytes: "340 MB", comesBack: false, button: "Move to Trash", note: "A half-finished install"),
    Item(id: "derived", title: "Xcode build files", bytes: "203 MB", comesBack: true, button: "Move to Trash"),
    Item(id: "nvidia", title: "Possible leftovers from NVIDIA", bytes: "146 MB", comesBack: false, button: "Move to Trash", note: "Possible: the app seems to be gone"),
]

/// One moment in a session: NVIDIA moved to the Trash, uv freed far less than "up to",
/// npm cleaning now, Cursor blocked, the rest waiting.
func midSession() -> [Item] {
    base.map { item in
        var i = item
        switch item.id {
        case "cursor": i.state = .blocked("Quit Cursor first, then try again.")
        case "uv": i.state = .done("Freed 120 MB.", putBack: false)
        case "npm": i.state = .cleaning
        case "nvidia": i.state = .done("Moved 146 MB to the Trash. Empty the Trash to get the space back.", putBack: true)
        default: i.state = .waiting
        }
        return i
    }
}

// MARK: - Stand-ins for the app's pieces

struct GlassButton: View {
    var title: String
    var prominent = false
    var dimmed = false
    var small = true
    var body: some View {
        Text(title)
            .font(small ? .callout : .body)
            .padding(.horizontal, small ? 10 : 14).padding(.vertical, small ? 3 : 5)
            .foregroundStyle(prominent ? Color.white : Color.primary)
            .background(Capsule().fill(prominent ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.fill.tertiary)))
            .overlay(Capsule().strokeBorder(Color.primary.opacity(prominent ? 0 : 0.08)))
            .opacity(dimmed ? 0.5 : 1)
            .fixedSize()
    }
}

struct CopyIcon: View {
    var body: some View {
        Image(systemName: "doc.on.clipboard").font(.system(size: 11))
            .frame(width: 24, height: 24)
            .background(Circle().fill(.fill.tertiary))
            .overlay(Circle().strokeBorder(Color.primary.opacity(0.08)))
    }
}

/// ImageRenderer can't draw ProgressView: a static quarter-open ring.
struct Spinner: View {
    var body: some View {
        Circle().trim(from: 0, to: 0.72)
            .stroke(secondary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .rotationEffect(.degrees(-90))
            .frame(width: 13, height: 13)
    }
}

struct PanelChrome<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Text("MacBook Pro").font(.system(size: 17, weight: .semibold))
                Spacer()
                HStack(spacing: 5) { Circle().fill(Color.gray).frame(width: 7, height: 7); Text("1 hidden").font(.callout) }
                    .padding(.horizontal, 10).padding(.vertical, 4).background(Capsule().fill(.fill.tertiary))
                Circle().fill(.fill.tertiary).frame(width: 26, height: 26)
                Circle().fill(.fill.tertiary).frame(width: 26, height: 26)
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
        .padding(12)
        .frame(width: 420, height: 620, alignment: .top)
    }
}

struct Module<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) { content }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.fill.quaternary))
    }
}

struct VerdictHeader: View {
    var extra: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Circle().fill(Color.gray).frame(width: 8, height: 8)
                Text("1 hidden").font(.system(.title3, design: .rounded).weight(.semibold))
            }
            Text(["Checked at 9:49 AM", extra].compactMap { $0 }.joined(separator: " · "))
                .font(.footnote).foregroundStyle(secondary)
        }
    }
}

struct StageRows: View {
    var compact = false
    let rows: [(String, String, Color?)] = [
        ("info.circle.fill", "Storage", nil), ("checkmark.circle.fill", "Protection", .green),
        ("checkmark.circle.fill", "Performance", .green), ("info.circle.fill", "Startup items", nil),
        ("info.circle.fill", "Apps", nil)]
    let figures = ["Up to 486 MB you could clear", "3 of 3 protections on", "Memory, heat, battery and disk are fine",
                   "1 item starts on its own", "1 possible leftover"]
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { i, r in
                HStack(spacing: 10) {
                    Image(systemName: r.0).foregroundStyle(r.2 ?? Color.gray).font(.system(size: 14))
                    Text(r.1).font(.callout)
                    Spacer(minLength: 8)
                    Text(figures[i]).font(.callout).foregroundStyle(secondary).lineLimit(1)
                }
                .frame(height: compact ? 24 : 28)
            }
        }
    }
}

struct BottomButtons: View {
    var body: some View {
        HStack(spacing: 8) { Spacer(); GlassButton(title: "Check again", small: false); GlassButton(title: "Done", small: false) }
    }
}

// MARK: - The row (shared by all directions; the trailing control is the state)

struct CleanRow: View {
    var item: Item
    var dense = false
    var grouped = false
    var fixedColumn = false

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title).font(.callout).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(Color.primary)
                if !dense || hasMessage { caption }
            }
            Spacer(minLength: 8)
            if dense && !hasMessage {
                Text("up to \(item.bytes)").font(.callout.monospacedDigit()).foregroundStyle(secondary)
            }
            trailing.frame(width: fixedColumn ? 112 : nil, alignment: .trailing)
        }
        .frame(minHeight: fixedColumn ? 48 : (dense ? 30 : 38))
    }

    private var isWaiting: Bool { if case .waiting = item.state { true } else { false } }
    private var hasMessage: Bool {
        switch item.state { case .ready, .waiting: item.note != nil; default: true }
    }

    @ViewBuilder private var caption: some View {
        switch item.state {
        case .ready, .waiting:
            Text(["up to \(item.bytes)", item.note ?? (item.comesBack && !grouped ? "Comes back as you work" : nil)].compactMap { $0 }.joined(separator: " · "))
                .font(.caption).foregroundStyle(secondary).lineLimit(2).fixedSize(horizontal: false, vertical: true)
        case .blocked(let msg):
            Text("up to \(item.bytes) · \(msg)").font(.caption).foregroundStyle(secondary).lineLimit(2)
        case .cleaning:
            Text(grouped ? "Cleaning. This can take a few minutes." : "up to \(item.bytes) · Cleaning").font(.caption).foregroundStyle(secondary)
        case .done(let msg, _):
            Text(msg).font(.caption).foregroundStyle(Color.primary).lineLimit(4).fixedSize(horizontal: false, vertical: true)
        case .failed(let msg):
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange).font(.system(size: 9))
                Text(msg).font(.caption).foregroundStyle(secondary)
            }
        }
    }

    @ViewBuilder private var trailing: some View {
        switch item.state {
        case .ready: GlassButton(title: item.button)
        case .waiting: GlassButton(title: item.button, dimmed: true)
        case .blocked: GlassButton(title: item.button, dimmed: true)
        case .cleaning: Spinner().frame(width: 40)
        case .done(_, let putBack):
            if putBack { GlassButton(title: "Put Back") } else { EmptyView() }
        case .failed: GlassButton(title: item.button)
        }
    }
}

// MARK: - Direction A: under the verdict, top three, confirm inside the row

struct DirectionA: View {
    var items: [Item]
    var confirming: String? = nil
    var body: some View {
        PanelChrome {
            Module {
                VerdictHeader(extra: confirming == nil ? "Freed 120 MB · 146 MB in the Trash" : nil)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Clean up").font(.callout.weight(.semibold)).foregroundStyle(secondary)
                    ForEach(items.prefix(3)) { item in
                        if item.id == confirming { InlineConfirm(item: item) } else { HStack(spacing: 8) { CleanRow(item: item); CopyIcon() } }
                    }
                    Text("+4 more").font(.footnote).foregroundStyle(secondary).frame(height: 22)
                }
                Divider()
                StageRows(compact: true)
                Spacer(minLength: 0)
                BottomButtons()
            }
        }
    }
}

struct InlineConfirm: View {
    var item: Item
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Clean \(item.title)?").font(.callout.weight(.semibold))
            Text("This uses uv's own cleanup to remove old Python package downloads that no project uses. It can free up to 10.2 GB. It can't be undone, but nothing you made is touched.")
                .font(.caption).foregroundStyle(secondary).fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Spacer()
                GlassButton(title: "Cancel", prominent: true)
                GlassButton(title: "Clean")
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.fill.tertiary))
        .padding(.vertical, 4)
    }
}

// MARK: - Direction B: its own screen, confirm as an in-panel sheet

struct DirectionBEntry: View {
    var body: some View {
        PanelChrome {
            Module {
                VerdictHeader(extra: "Freed 120 MB")
                StageRows()
                HStack(spacing: 10) {
                    Image(systemName: "trash").font(.system(size: 13)).foregroundStyle(secondary).frame(width: 16)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Clean up").font(.callout)
                        Text("7 things Vitals can clear for you, one at a time").font(.caption).foregroundStyle(secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold)).foregroundStyle(secondary)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.fill.tertiary))
                Divider()
                Text("Biggest wins").font(.callout.weight(.semibold)).foregroundStyle(secondary)
                ForEach([("Codex install leftover", "up to 340 MB · A half-finished install"),
                         ("Possible leftovers from NVIDIA", "up to 146 MB · Possible: the app seems to be gone")], id: \.0) { w in
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(w.0).font(.callout); Text(w.1).font(.caption).foregroundStyle(secondary)
                        }
                        Spacer(); CopyIcon()
                    }
                }
                Spacer(minLength: 0)
                BottomButtons()
            }
        }
    }
}

struct DirectionB: View {
    var items: [Item]
    var sheet = false
    var body: some View {
        PanelChrome {
            ZStack {
                Module {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left").font(.system(size: 12, weight: .semibold))
                            .frame(width: 26, height: 26).background(Circle().fill(.fill.tertiary))
                        Text("Clean up").font(.system(.title3, design: .rounded).weight(.semibold))
                    }
                    Text("Freed 120 MB · 146 MB in the Trash").font(.footnote).foregroundStyle(secondary)
                    VStack(spacing: 4) {
                        ForEach(items) { item in
                            HStack(spacing: 8) { CleanRow(item: item); CopyIcon() }
                        }
                    }
                    Spacer(minLength: 0)
                    HStack { Spacer(); GlassButton(title: "Done", small: false) }
                }
                if sheet {
                    RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.black.opacity(0.28))
                    SheetConfirm().padding(.horizontal, 22)
                }
            }
        }
    }
}

struct SheetConfirm: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Clean Python download cache (uv)?").font(.body.weight(.semibold))
            Text("This uses uv's own cleanup to remove old Python package downloads that no project uses. It can free up to 10.2 GB. It can't be undone, but nothing you made is touched.")
                .font(.callout).foregroundStyle(secondary).fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Spacer()
                GlassButton(title: "Cancel", prominent: true, small: false)
                GlassButton(title: "Clean", small: false)
            }
            .padding(.top, 2)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(nsColor: .controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color.primary.opacity(0.12)))
        .shadow(color: .black.opacity(0.25), radius: 18, y: 6)
    }
}

// MARK: - Direction C: every row, dense, after the wins; NSAlert to confirm

struct DirectionC: View {
    var items: [Item]
    var alert = false
    var body: some View {
        ZStack {
            PanelChrome {
                Module {
                    Text("Biggest wins").font(.callout.weight(.semibold)).foregroundStyle(secondary)
                    ForEach([("Codex install leftover", "up to 340 MB · A half-finished install"),
                             ("Possible leftovers from NVIDIA", "up to 146 MB · Possible: the app seems to be gone")], id: \.0) { w in
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(w.0).font(.callout); Text(w.1).font(.caption).foregroundStyle(secondary)
                            }
                            Spacer(); CopyIcon()
                        }
                    }
                    Divider()
                    HStack {
                        Text("Clean up").font(.callout.weight(.semibold)).foregroundStyle(secondary)
                        Spacer()
                        Text("Freed 120 MB · 146 MB in the Trash").font(.footnote).foregroundStyle(secondary)
                    }
                    VStack(spacing: 2) { ForEach(items) { item in HStack(spacing: 8) { CleanRow(item: item, dense: true); CopyIcon() }.frame(minHeight: 34) } }
                    Spacer(minLength: 0)
                    BottomButtons()
                }
            }
            if alert { AlertMock().offset(y: -40) }
        }
        .frame(width: 420, height: 620)
    }
}

/// NSAlert can't be rendered offscreen: a drawn look-alike of macOS 26's alert.
struct AlertMock: View {
    var body: some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.fill.secondary).frame(width: 48, height: 48)
            Text("Clean Python download cache (uv)?").font(.body.weight(.bold)).multilineTextAlignment(.center)
            Text("This uses uv's own cleanup to remove old Python package downloads that no project uses. It can free up to 10.2 GB. It can't be undone, but nothing you made is touched.")
                .font(.callout).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 6) {
                Text("Cancel").font(.body).foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 28)
                    .background(Capsule().fill(Color.accentColor))
                Text("Clean").font(.body).frame(maxWidth: .infinity).frame(height: 28)
                    .background(Capsule().fill(.fill.tertiary))
            }
            .padding(.top, 4)
        }
        .padding(18)
        .frame(width: 260)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.background))
        .shadow(color: .black.opacity(0.35), radius: 24, y: 10)
    }
}

// MARK: - Direction B2: B with what fits from CleanMyMac's Manager sheet
// Borrowed: a real icon per row, Back + centred title, a footer with the running total and Done.
// Not borrowed (Vitals rules): checkboxes and one Run for all, a "junk" total, colour, glossy renders.

func icon(_ id: String) -> NSImage {
    let apps = ["cursor": "/Applications/Cursor.app", "derived": "/Applications/Xcode.app", "codex": "/Applications/ChatGPT.app"]
    if let path = apps[id], FileManager.default.fileExists(atPath: path) { return NSWorkspace.shared.icon(forFile: path) }
    return NSWorkspace.shared.icon(for: .folder)
}

struct DirectionB2: View {
    var items: [Item]
    var sheet = false
    var body: some View {
        PanelChrome {
            ZStack {
                VStack(spacing: 0) {
                    ZStack {
                        HStack {
                            Image(systemName: "chevron.left").font(.system(size: 12, weight: .semibold))
                                .frame(width: 26, height: 26).background(Circle().fill(.fill.tertiary))
                            Spacer()
                        }
                        Text("Clean up").font(.body.weight(.semibold))
                    }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    Divider()
                    VStack(spacing: 2) {
                        ForEach(items) { item in
                            HStack(spacing: 10) {
                                Image(nsImage: icon(item.id)).resizable().frame(width: 28, height: 28)
                                CleanRow(item: item)
                                CopyIcon()
                            }
                        }
                    }
                    .padding(.horizontal, 14).padding(.top, 8)
                    Spacer(minLength: 0)
                    Divider()
                    HStack {
                        Text("Freed 120 MB · 146 MB in the Trash").font(.callout).foregroundStyle(secondary)
                        Spacer()
                        GlassButton(title: "Done", small: false)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.fill.quaternary))
                if sheet {
                    RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.black.opacity(0.28))
                    SheetConfirm().padding(.horizontal, 22)
                }
            }
        }
    }
}

// MARK: - B3: B2 after the critique (Nov 14)
// 1. The way to clean starts on the result card: Biggest wins rows get their own button, and a
//    "Clean up" row (count, chevron) opens the full list.
// 2. Confirmation is NSAlert (Escape closes the popover, so an in-panel sheet would fight it).
// 3. A long clean says so; reopening the panel mid-clean shows it on the result card's Clean up row.
// 4. The list is grouped: "Stays free" (its total matches the Storage line) then "Comes back as you work".
//    One way back (the chevron); the footer carries only measured totals.

func stays(_ items: [Item]) -> [Item] { items.filter { !$0.comesBack } }
func refills(_ items: [Item]) -> [Item] { items.filter { $0.comesBack } }

struct WinRowB3: View {
    var item: Item
    var body: some View {
        HStack(spacing: 10) {
            Image(nsImage: icon(item.id)).resizable().frame(width: 28, height: 28)
            CleanRow(item: item, fixedColumn: true)
            CopyIcon()
        }
    }
}

struct CleanUpEntry: View {
    var cleaning: String? = nil
    var body: some View {
        HStack(spacing: 8) {
            Text("Clean up").font(.callout)
            Spacer(minLength: 8)
            if let cleaning {
                Spinner()
                Text("Cleaning \(cleaning)").font(.callout).foregroundStyle(secondary).lineLimit(1)
            } else {
                Text("7 items").font(.callout).foregroundStyle(secondary)
            }
            Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold)).foregroundStyle(secondary)
        }
        .padding(.horizontal, 10).frame(height: 36)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.fill.tertiary))
    }
}

struct ResultB3: View {
    var items: [Item]
    var cleaning: String? = nil
    var totals: String? = nil
    var alert = false
    var alertClean = false
    var body: some View {
        ZStack {
            PanelChrome {
                Module {
                    VerdictHeader(extra: totals)
                    StageRows(compact: true)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Also needs a look").font(.callout.weight(.semibold)).foregroundStyle(secondary)
                        HStack(spacing: 10) {
                            Image(systemName: "xmark.octagon.fill").foregroundStyle(.red.opacity(0.45)).font(.system(size: 14))
                            Text("Backups").font(.callout)
                            Spacer()
                            Text("Hidden").font(.callout).foregroundStyle(secondary)
                        }
                        .frame(height: 26)
                    }
                    Divider()
                    CleanUpEntry(cleaning: cleaning)
                    Text("Biggest wins").font(.callout.weight(.semibold)).foregroundStyle(secondary)
                    ForEach(stays(items)) { WinRowB3(item: $0) }
                    HStack {
                        Text("Rebuilds itself").font(.callout).foregroundStyle(secondary)
                        Spacer()
                        Text("35.7 GB").font(.callout.monospacedDigit()).foregroundStyle(secondary)
                    }
                    Spacer(minLength: 0)
                    BottomButtons()
                }
            }
            if alert { AlertTrash().offset(y: -20) }
            if alertClean { AlertMock().offset(y: -20) }
        }
        .frame(width: 420, height: 620)
    }
}

/// NSAlert can't be rendered offscreen: a look-alike. The real one appears centred on the screen
/// with Vitals' icon; Return and Escape both mean Cancel (the default).
struct AlertTrash: View {
    var body: some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.fill.secondary).frame(width: 48, height: 48)
                .overlay(Text("app icon").font(.system(size: 8)).foregroundStyle(.tertiary))
            Text("Move Possible leftovers from NVIDIA to the Trash?").font(.body.weight(.bold)).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text("This moves the data folder of NVIDIA to the Trash (up to 146 MB). The app seems to be gone, but check it isn't one you still use. You can put it back until you empty the Trash.")
                .font(.callout).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 6) {
                Text("Cancel").font(.body).foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 28)
                    .background(Capsule().fill(Color.accentColor))
                Text("Move to Trash").font(.body).frame(maxWidth: .infinity).frame(height: 28)
                    .background(Capsule().fill(.fill.tertiary))
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

struct CleanUpB3: View {
    var items: [Item]
    var totals: String? = nil
    var busy: String? = nil
    var body: some View {
        PanelChrome {
            VStack(spacing: 0) {
                ZStack {
                    HStack {
                        Image(systemName: "chevron.left").font(.system(size: 12, weight: .semibold))
                            .frame(width: 26, height: 26).background(Circle().fill(.fill.tertiary))
                        Spacer()
                    }
                    Text("Clean up").font(.body.weight(.semibold))
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                Divider()
                VStack(alignment: .leading, spacing: 2) {
                    if let busy {
                    Text("One at a time. \(busy) is cleaning.").font(.caption).foregroundStyle(secondary).frame(height: 18)
                }
                group("Stays free", stayFigure, stays(items))
                    group("Comes back as you work", nil, refills(items)).padding(.top, 6)
                }
                .padding(.horizontal, 14).padding(.top, 8)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 0, maxHeight: .infinity, alignment: .top)
                .clipped()
                if let totals {
                    Divider()
                    HStack { Text(totals).font(.callout).foregroundStyle(secondary); Spacer() }
                        .padding(.horizontal, 14).frame(height: 40)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.fill.quaternary))
        }
    }

    /// Recounted from the rows still offered, so it never contradicts a finished row.
    var stayFigure: String? {
        let mb = stays(items).filter { if case .done = $0.state { false } else { true } }
            .compactMap { Double($0.bytes.replacingOccurrences(of: " MB", with: "")) }.reduce(0, +)
        return mb > 0 ? "up to \(Int(mb)) MB" : nil
    }

    @ViewBuilder func group(_ title: String, _ figure: String?, _ rows: [Item]) -> some View {
        HStack {
            Text(title).font(.callout.weight(.semibold)).foregroundStyle(secondary)
            Spacer()
            if let figure { Text(figure).font(.callout).foregroundStyle(secondary) }
        }
        .frame(height: 24)
        ForEach(rows) { item in
            HStack(spacing: 10) {
                Image(nsImage: icon(item.id)).resizable().frame(width: 28, height: 28)
                CleanRow(item: item, grouped: true, fixedColumn: true)
                CopyIcon()
            }
        }
    }
}

// MARK: - Render

@MainActor func render<V: View>(_ view: V, _ path: String, dark: Bool) {
    let bg = dark ? Color(red: 0.137, green: 0.137, blue: 0.145) : Color(red: 0.925, green: 0.925, blue: 0.933)
    let v = view.background(bg).environment(\.colorScheme, dark ? .dark : .light)
    NSApplication.shared.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
    var png: Data?
    NSApplication.shared.appearance!.performAsCurrentDrawingAppearance {
        let r = ImageRenderer(content: v); r.scale = 2; r.isOpaque = true
        if let cg = r.cgImage, let space = CGColorSpace(name: CGColorSpace.sRGB),
           let ctx = CGContext(data: nil, width: cg.width, height: cg.height, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                               bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
            if let out = ctx.makeImage() { png = NSBitmapImageRep(cgImage: out).representation(using: .png, properties: [:]) }
        }
    }
    guard let png else { print("fail \(path)"); return }
    try? png.write(to: URL(fileURLWithPath: path)); print("wrote \(path)")
}

@main struct Render {
    @MainActor static func main() {
        let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
        let mid = midSession()
        var readyUV = base; readyUV[1].state = .ready
        let shots: [(String, AnyView)] = [
            ("A-1-session", AnyView(DirectionA(items: mid))),
            ("A-2-confirm", AnyView(DirectionA(items: base, confirming: "uv"))),
            ("B-1-entry", AnyView(DirectionBEntry())),
            ("B-2-session", AnyView(DirectionB(items: mid))),
            ("B-3-confirm", AnyView(DirectionB(items: base, sheet: true))),
            ("B2-session", AnyView(DirectionB2(items: mid))),
            ("B2-confirm", AnyView(DirectionB2(items: base, sheet: true))),
            ("B3-1-result", AnyView(ResultB3(items: base))),
            ("B3-2-confirm", AnyView(ResultB3(items: base, alert: true))),
            ("B3-2b-confirm-clean", AnyView(ResultB3(items: base, alertClean: true))),
            ("B3-3-cleanup", AnyView(CleanUpB3(items: base))),
            ("B3-4-session", AnyView(CleanUpB3(items: mid, totals: "Freed 120 MB · 146 MB in the Trash", busy: "npm cache"))),
            ("B3-5-reopened", AnyView(ResultB3(items: mid, cleaning: "npm cache", totals: "Freed 120 MB · 146 MB in the Trash"))),
            ("C-1-session", AnyView(DirectionC(items: mid))),
            ("C-2-confirm", AnyView(DirectionC(items: base, alert: true))),
        ]
        for (name, view) in shots {
            render(view, "\(out)/\(name)-light.png", dark: false)
            render(view, "\(out)/\(name)-dark.png", dark: true)
        }
    }
}
