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
        case "uv": i.state = .done("Freed 120 MB. The rest is still in use.", putBack: false)
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
            .opacity(dimmed ? 0.4 : 1)
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

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title).font(.callout).lineLimit(1)
                    .foregroundStyle(Color.primary)
                if !dense || hasMessage { caption }
            }
            Spacer(minLength: 8)
            if dense && !hasMessage {
                Text("up to \(item.bytes)").font(.callout.monospacedDigit()).foregroundStyle(secondary)
            }
            trailing
        }
        .frame(minHeight: dense ? 30 : 38)
    }

    private var isWaiting: Bool { if case .waiting = item.state { true } else { false } }
    private var hasMessage: Bool {
        switch item.state { case .ready, .waiting: item.note != nil; default: true }
    }

    @ViewBuilder private var caption: some View {
        switch item.state {
        case .ready, .waiting:
            Text(["up to \(item.bytes)", item.note ?? (item.comesBack ? "Comes back as you work" : nil)].compactMap { $0 }.joined(separator: " · "))
                .font(.caption).foregroundStyle(secondary).lineLimit(1)
        case .blocked(let msg):
            Text("up to \(item.bytes) · \(msg)").font(.caption).foregroundStyle(secondary).lineLimit(2)
        case .cleaning:
            Text("up to \(item.bytes) · Cleaning").font(.caption).foregroundStyle(secondary)
        case .done(let msg, _):
            Text(msg).font(.caption).foregroundStyle(Color.primary).lineLimit(2).fixedSize(horizontal: false, vertical: true)
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
            ("C-1-session", AnyView(DirectionC(items: mid))),
            ("C-2-confirm", AnyView(DirectionC(items: base, alert: true))),
        ]
        for (name, view) in shots {
            render(view, "\(out)/\(name)-light.png", dark: false)
            render(view, "\(out)/\(name)-dark.png", dark: true)
        }
    }
}
