// Clean buttons: three motion studies on direction B2, drawn frame by frame with real SwiftUI, offscreen.
// Run: swiftc -parse-as-library -target arm64-apple-macosx26.0 -o /tmp/cbm Motion.swift && /tmp/cbm out
// then ffmpeg turns each frames folder into a video.
// Springs are critically damped (Apple's default: damping 1.0, response 0.35 s), so nothing bounces.
// The storyboard: uv is cleaned (and frees far less than "up to"), then NVIDIA goes to the Trash,
// then Put Back. The confirmation sheet is cut from the videos (it comes between press and work).
import SwiftUI
import AppKit

let secondary = Color.primary.opacity(0.72)

// MARK: - Timing

/// Critically damped spring step response, 0 → 1. `response` in seconds (Apple's term).
func spring(_ t: Double, response: Double = 0.35) -> Double {
    guard t > 0 else { return 0 }
    let w = 2 * Double.pi / response
    return 1 - (1 + w * t) * exp(-w * t)
}
func ease(_ t: Double, from a: Double, _ resp: Double = 0.35) -> Double { spring(t - a, response: resp) }
func clamp(_ x: Double) -> Double { min(1, max(0, x)) }
func lerp(_ a: Double, _ b: Double, _ p: Double) -> Double { a + (b - a) * p }

// Storyboard times (seconds)
enum T {
    static let uvPress = 0.6, uvWork = 0.75, uvDone = 2.6
    static let nvPress = 3.6, nvWork = 3.75, nvDone = 5.0
    static let putBack = 6.8, putBackDone = 7.4
    static let end = 8.6
}

// MARK: - Data

struct Item: Identifiable {
    let id: String; let title: String; let bytes: Double /* MB */; let size: String
    let caption: String; let button: String; let lasting: Bool
}
let items: [Item] = [
    Item(id: "cursor", title: "Cursor snapshots", bytes: 10844, size: "10.8 GB", caption: "up to 10.8 GB · Comes back as you work", button: "Move to Trash", lasting: false),
    Item(id: "uv", title: "Python download cache (uv)", bytes: 10165, size: "10.2 GB", caption: "up to 10.2 GB · Comes back as you work", button: "Clean", lasting: false),
    Item(id: "npm", title: "npm cache", bytes: 3300, size: "3.3 GB", caption: "up to 3.3 GB · Comes back as you work", button: "Clean", lasting: false),
    Item(id: "pnpm", title: "pnpm store", bytes: 850, size: "850 MB", caption: "up to 850 MB · Comes back as you work", button: "Clean", lasting: false),
    Item(id: "codex", title: "Codex install leftover", bytes: 340, size: "340 MB", caption: "up to 340 MB · A half-finished install", button: "Move to Trash", lasting: true),
    Item(id: "derived", title: "Xcode build files", bytes: 203, size: "203 MB", caption: "up to 203 MB · Comes back as you work", button: "Move to Trash", lasting: false),
    Item(id: "nvidia", title: "Possible leftovers from NVIDIA", bytes: 146, size: "146 MB", caption: "up to 146 MB · Possible: the app seems to be gone", button: "Move to Trash", lasting: true),
]

func icon(_ id: String) -> NSImage {
    let apps = ["cursor": "/Applications/Cursor.app", "derived": "/Applications/Xcode.app", "codex": "/Applications/ChatGPT.app"]
    if let p = apps[id], FileManager.default.fileExists(atPath: p) { return NSWorkspace.shared.icon(forFile: p) }
    return NSWorkspace.shared.icon(for: .folder)
}
let icons = Dictionary(uniqueKeysWithValues: items.map { ($0.id, icon($0.id)) })

enum Study: String, CaseIterable { case morph = "M1-morph", trash = "M2-trash", squares = "M3-squares" }

struct Spots: PreferenceKey {
    static let defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) { value.merge(nextValue()) { $1 } }
}

/// M2 timeline: out to the Trash, back on Put Back, along the same path.
enum Fly {
    static let outStart = T.nvDone, outLand = T.nvDone + 0.45
    static let backStart = T.putBack + 0.05, backLand = T.putBack + 0.5
    static func inTrash(_ t: Double) -> Bool { t >= outLand && t < backStart }
    static func flying(_ t: Double) -> Bool { (t >= outStart && t < outLand) || (t >= backStart && t < backLand) }
    static func glyphShown(_ t: Double) -> Bool { t >= outStart - 0.1 && t < backLand + 0.35 }
    static let freedStart = T.uvDone + 0.15, freedLand = T.uvDone + 0.65
}

// MARK: - Layout constants (fixed so the flying icon knows where it is)

let rowH: CGFloat = 44
let headerH: CGFloat = 46
let pad: CGFloat = 14

// MARK: - Pieces

struct Capsuleish: View {
    var title: String; var t: Double; var press: Double; var work: Double; var done: Double
    var body: some View {
        // press → scale 0.97 instantly; work → capsule shrinks to a 22 pt ring; done → ring fades.
        let pressed = t >= press && t < work
        let m = clamp(ease(t, from: work, 0.3))
        let gone = clamp(ease(t, from: done, 0.3))
        let fullW: CGFloat = title == "Clean" ? 56 : 112
        let w = lerp(Double(fullW), 22, m)
        ZStack {
            Capsule().fill(.fill.tertiary).opacity(1 - m)
            Capsule().strokeBorder(Color.primary.opacity(0.08)).opacity(1 - m)
            Text(title).font(.callout).opacity(1 - clamp(m * 2)).fixedSize()
            // indeterminate ring: the tool reports no progress, so the arc only turns
            Circle().trim(from: 0, to: 0.7)
                .stroke(secondary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 14, height: 14)
                .rotationEffect(.degrees((t - work) * 300))
                .opacity(clamp((m - 0.6) * 2.5) * (1 - gone))
        }
        .frame(width: CGFloat(w), height: 22)
        .scaleEffect(pressed ? 0.97 : 1)
        .opacity(1 - gone)
        .frame(width: title == "Clean" ? 56 : 112, alignment: .trailing)
    }
}

struct CopyIcon: View {
    var body: some View {
        Image(systemName: "doc.on.clipboard").font(.system(size: 11)).frame(width: 24, height: 24)
            .background(Circle().fill(.fill.tertiary)).overlay(Circle().strokeBorder(Color.primary.opacity(0.08)))
    }
}

struct PutBackButton: View {
    var t: Double
    var body: some View {
        let appear = clamp(ease(t, from: T.nvDone + 0.25, 0.3))
        let pressed = t >= T.putBack && t < T.putBack + 0.12
        let gone = clamp(ease(t, from: T.putBack + 0.15, 0.25))
        Text("Put Back").font(.callout).padding(.horizontal, 10).padding(.vertical, 3)
            .background(Capsule().fill(.fill.tertiary)).overlay(Capsule().strokeBorder(Color.primary.opacity(0.08)))
            .scaleEffect(pressed ? 0.97 : 1)
            .opacity(appear * (1 - gone)).fixedSize()
    }
}

/// A caption that cross-fades with a small upward slide (Reduce Motion: the fade only).
struct SwapText: View {
    var old: String; var new: String; var p: Double; var newPrimary = true
    var body: some View {
        ZStack(alignment: .topLeading) {
            Text(old).foregroundStyle(secondary).opacity(1 - p).offset(y: CGFloat(-6 * p))
            Text(new).foregroundStyle(newPrimary ? Color.primary : secondary).opacity(p).offset(y: CGFloat(6 * (1 - p)))
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.caption).lineLimit(3)
    }
}

struct Row: View {
    var item: Item; var t: Double; var study: Study
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                    .opacity(1 - iconOpacity)
                Image(nsImage: icons[item.id]!).resizable().opacity(iconOpacity)
            }
            .frame(width: 28, height: 28)
            .anchorPreference(key: Spots.self, value: .bounds) { [item.id: $0] }
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title).font(.callout).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                caption
            }
            Spacer(minLength: 8)
            trailing
            CopyIcon()
        }
        .frame(minHeight: rowH)
    }

    /// M2: the icon leaves its row for the Trash and comes back on Put Back (the flying copy is drawn above).
    private var iconOpacity: Double {
        guard study == .trash, item.id == "nvidia" else { return 1 }
        return (t >= Fly.outStart && t < Fly.backLand) ? 0 : 1
    }

    @ViewBuilder private var caption: some View {
        switch item.id {
        case "uv":
            let cleaning = clamp(ease(t, from: T.uvWork, 0.3))
            let done = clamp(ease(t, from: T.uvDone, 0.35))
            if t < T.uvDone { SwapText(old: item.caption, new: "up to 10.2 GB · Cleaning", p: cleaning, newPrimary: false) }
            else { SwapText(old: "up to 10.2 GB · Cleaning", new: "Freed 120 MB. The rest is still in use.", p: done)
                .anchorPreference(key: Spots.self, value: .bounds) { ["uvcap": $0] } }
        case "nvidia":
            let cleaning = clamp(ease(t, from: T.nvWork, 0.3))
            let done = clamp(ease(t, from: T.nvDone, 0.35))
            let back = clamp(ease(t, from: T.putBackDone, 0.35))
            if t < T.nvDone { SwapText(old: item.caption, new: "up to 146 MB · Moving to the Trash", p: cleaning, newPrimary: false) }
            else if t < T.putBackDone { SwapText(old: "up to 146 MB · Moving to the Trash", new: "Moved 146 MB to the Trash. Empty the Trash to get the space back.", p: done) }
            else { SwapText(old: "Moved 146 MB to the Trash. Empty the Trash to get the space back.", new: item.caption, p: back, newPrimary: false) }
        default:
            Text(item.caption).font(.caption).foregroundStyle(secondary).lineLimit(2).fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder private var trailing: some View {
        let busy = (t >= T.uvPress && t < T.uvDone) || (t >= T.nvPress && t < T.nvDone)
        switch item.id {
        case "uv": Capsuleish(title: "Clean", t: t, press: T.uvPress, work: T.uvWork, done: T.uvDone)
        case "nvidia":
            if t < T.nvDone + 0.25 { Capsuleish(title: "Move to Trash", t: t, press: T.nvPress, work: T.nvWork, done: T.nvDone) }
            else if t < T.putBackDone { PutBackButton(t: t) }
            else {
                Text("Move to Trash").font(.callout).padding(.horizontal, 10).padding(.vertical, 3)
                    .background(Capsule().fill(.fill.tertiary)).overlay(Capsule().strokeBorder(Color.primary.opacity(0.08)))
                    .opacity(clamp(ease(t, from: T.putBackDone, 0.3))).fixedSize()
            }
        default:
            // one action at a time: the others dim while something runs
            Text(item.button).font(.callout).padding(.horizontal, 10).padding(.vertical, 3)
                .background(Capsule().fill(.fill.tertiary)).overlay(Capsule().strokeBorder(Color.primary.opacity(0.08)))
                .opacity(busy ? 0.4 : 1).fixedSize()
        }
    }
}

// MARK: - Footer: measured totals only, counting up

struct Footer: View {
    var t: Double; var study: Study
    var body: some View {
        let m2 = study == .trash
        // Measured figures only, shown whole (never counted up through numbers that weren't measured).
        let freedShown = clamp(ease(t, from: T.uvDone, 0.3))
        let trashText = m2
            ? clamp(ease(t, from: Fly.outLand, 0.3)) * (1 - clamp(ease(t, from: Fly.backStart, 0.25)))
            : clamp(ease(t, from: T.nvDone + 0.35, 0.4)) * (1 - clamp(ease(t, from: T.putBack + 0.4, 0.4)))
        let glyphIn = clamp(ease(t, from: Fly.outStart - 0.1, 0.25)) * (1 - clamp(ease(t, from: Fly.backLand + 0.1, 0.25)))
        let trashPart = m2 ? Fly.glyphShown(t) || trashText > 0.01 : trashText > 0.01
        HStack(spacing: 6) {
            Text("Freed 120 MB").opacity(freedShown)
                .anchorPreference(key: Spots.self, value: .bounds) { ["freed": $0] }
            if trashPart {
                Text("·").opacity(max(trashText, m2 ? glyphIn : 0))
                if m2 {
                    // The Trash glyph belongs to the Trash figure, and shows only while something is in it.
                    Image(systemName: Fly.inTrash(t) ? "trash.fill" : "trash")
                        .font(.system(size: 13)).frame(width: 16)
                        .scaleEffect(1 + 0.14 * bump(t, at: Fly.outLand - 0.05) + 0.14 * bump(t, at: Fly.backStart - 0.05))
                        .opacity(glyphIn)
                        .anchorPreference(key: Spots.self, value: .bounds) { ["trash": $0] }
                }
                Text("146 MB in the Trash").opacity(trashText).offset(y: CGFloat(3 * (1 - trashText)))
            }
            Spacer(minLength: 8)
            Text("Done").font(.body).foregroundStyle(Color.primary).padding(.horizontal, 14).padding(.vertical, 5)
                .background(Capsule().fill(.fill.tertiary)).overlay(Capsule().strokeBorder(Color.primary.opacity(0.08)))
        }
        .font(.callout.monospacedDigit()).foregroundStyle(secondary)
        .padding(.horizontal, pad).frame(height: 50)
    }
    /// A small swell when something lands in or leaves the Trash (no wobble).
    func bump(_ t: Double, at a: Double) -> Double { let x = t - a; return x > 0 && x < 0.4 ? sin(.pi * x / 0.4) : 0 }
}

// MARK: - M3: the squares (Smart Check's own tally: 1 square = 100 MB, a pale square for the part)

struct Squares: View {
    var t: Double
    let unit = 100.0, side: CGFloat = 6, gap: CGFloat = 2, perRow = 45

    struct Cell { var item: String; var kind: Int /* 0 empty slot, 1 whole, 2 part */ ; var lasting: Bool; var index: Int; var count: Int }

    var cells: [Cell] {
        var out: [Cell] = []
        for (n, it) in items.enumerated() {
            let whole = Int(it.bytes / unit), part = it.bytes.truncatingRemainder(dividingBy: unit) > 0
            let count = whole + (part ? 1 : 0)
            for i in 0..<count { out.append(Cell(item: it.id, kind: i < whole ? 1 : 2, lasting: it.lasting, index: i, count: count)) }
            if n < items.count - 1 { out.append(Cell(item: "", kind: 0, lasting: false, index: 0, count: 0)) }
        }
        return out
    }

    var body: some View {
        let cs = cells
        let rows = (cs.count + perRow - 1) / perRow
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: gap) {
                ForEach(0..<rows, id: \.self) { r in
                    HStack(spacing: gap) {
                        ForEach(0..<perRow, id: \.self) { c in
                            let i = r * perRow + c
                            if i < cs.count { cell(cs[i]) } else { Color.clear.frame(width: side, height: side) }
                        }
                    }
                }
            }
            HStack(spacing: 12) {
                key(fill: Color.primary, "Lasting")
                key(fill: Color.primary.opacity(0.35), "Comes back")
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 1.5).strokeBorder(Color.primary.opacity(0.7), lineWidth: 1).frame(width: side, height: side)
                    Text("In the Trash").font(.caption).foregroundStyle(secondary)
                }
                Spacer()
                Text("1 square = 100 MB").font(.caption).foregroundStyle(secondary)
            }
        }
    }

    func key(fill: Color, _ s: String) -> some View {
        HStack(spacing: 4) { RoundedRectangle(cornerRadius: 1.5).fill(fill).frame(width: side, height: side); Text(s).font(.caption).foregroundStyle(secondary) }
    }

    @ViewBuilder func cell(_ c: Cell) -> some View {
        if c.kind == 0 { Color.clear.frame(width: side, height: side) }
        else {
            let base = c.lasting ? Color.primary : Color.primary.opacity(0.35)
            let part = c.kind == 2
            // uv freed 120 MB: one whole square and a part leave, from the end of its run, the rest stay.
            let freedFade: Double = {
                guard c.item == "uv", c.index >= c.count - 2 else { return 0 }
                return clamp(ease(t, from: T.uvDone + 0.1 * Double(c.count - 1 - c.index), 0.35))
            }()
            // NVIDIA: hollow while in the Trash, filled again after Put Back.
            let hollow: Double = c.item == "nvidia"
                ? clamp(ease(t, from: T.nvDone + 0.1 * Double(c.index), 0.35)) * (1 - clamp(ease(t, from: T.putBackDone - 0.2, 0.35)))
                : 0
            ZStack {
                RoundedRectangle(cornerRadius: 1.5).strokeBorder(Color.primary.opacity(0.12), lineWidth: 1).opacity(freedFade)
                RoundedRectangle(cornerRadius: 1.5).fill(base.opacity(part ? 0.45 : 1)).opacity((1 - freedFade) * (1 - hollow))
                RoundedRectangle(cornerRadius: 1.5).strokeBorder(Color.primary.opacity(0.7), lineWidth: 1).opacity(hollow)
            }
            .frame(width: side, height: side)
        }
    }
}

// MARK: - The screen

struct Screen: View {
    var t: Double; var study: Study
    var body: some View {
        VStack(spacing: 10) {
            chrome
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    VStack(spacing: 0) {
                        ZStack {
                            HStack {
                                Image(systemName: "chevron.left").font(.system(size: 12, weight: .semibold))
                                    .frame(width: 26, height: 26).background(Circle().fill(.fill.tertiary))
                                Spacer()
                            }
                            Text("Clean up").font(.body.weight(.semibold))
                        }
                        .padding(.horizontal, pad).frame(height: headerH)
                        Divider()
                        if study == .squares { Squares(t: t).padding(.horizontal, pad).padding(.top, 10).padding(.bottom, 4) }
                        VStack(spacing: 0) { ForEach(items) { Row(item: $0, t: t, study: study) } }
                            .padding(.horizontal, pad).padding(.top, 6)
                        Spacer(minLength: 0)
                        Divider()
                        Footer(t: t, study: study)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
                .overlayPreferenceValue(Spots.self) { spots in
                    GeometryReader { g in if study == .trash { fliers(spots, g) } }
                }
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.fill.quaternary))
            }
        }
        .padding(12)
        .frame(width: 420, height: 620, alignment: .top)
    }

    /// M2: NVIDIA's icon flies on a short arc from its row into the Trash glyph, shrinking as it lands,
    /// and back along the same path on Put Back.
    @ViewBuilder func fliers(_ spots: [String: Anchor<CGRect>], _ g: GeometryProxy) -> some View {
        if let row = spots["nvidia"], let bin = spots["trash"], Fly.flying(t) {
            let a = g[row], b = g[bin]
            let out = t < Fly.backStart
            let p = out ? spring(t - Fly.outStart, response: 0.45) : 1 - spring(t - Fly.backStart, response: 0.45)
            let x = lerp(a.midX, b.midX, p) + 26 * sin(.pi * p)
            let y = lerp(a.midY, b.midY, p) - 18 * sin(.pi * p)
            let size = lerp(28, 11, p)
            Image(nsImage: icons["nvidia"]!).resizable().frame(width: CGFloat(size), height: CGFloat(size))
                .opacity(1 - 0.7 * clamp((p - 0.8) / 0.2))
                .position(x: CGFloat(x), y: CGFloat(y))
        }
    }

    var chrome: some View {
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
                ForEach(["Overview", "Chip", "Memory", "Processes", "Battery", "Health"], id: \.self) { s in
                    Text(s).font(.callout.weight(s == "Overview" ? .semibold : .regular)).frame(maxWidth: .infinity).frame(height: 22)
                }
            }
            .padding(2).background(RoundedRectangle(cornerRadius: 9).fill(.fill.tertiary))
        }
    }
}

// MARK: - Render

@MainActor func png<V: View>(_ view: V, dark: Bool) -> Data? {
    let bg = dark ? Color(red: 0.137, green: 0.137, blue: 0.145) : Color(red: 0.925, green: 0.925, blue: 0.933)
    let v = view.background(bg).environment(\.colorScheme, dark ? .dark : .light)
    NSApplication.shared.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
    var out: Data?
    NSApplication.shared.appearance!.performAsCurrentDrawingAppearance {
        let r = ImageRenderer(content: v); r.scale = 2; r.isOpaque = true
        if let cg = r.cgImage, let space = CGColorSpace(name: CGColorSpace.sRGB),
           let ctx = CGContext(data: nil, width: cg.width, height: cg.height, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                               bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
            if let img = ctx.makeImage() { out = NSBitmapImageRep(cgImage: img).representation(using: .png, properties: [:]) }
        }
    }
    return out
}

@main struct Render {
    @MainActor static func main() {
        let root = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
        let fps = 30.0
        let dark = CommandLine.arguments.contains("--dark")
        for study in Study.allCases {
            let dir = "\(root)/\(study.rawValue)\(dark ? "-dark" : "")"
            try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
            for f in 0..<Int(T.end * fps) {
                let t = Double(f) / fps
                if let d = png(Screen(t: t, study: study), dark: dark) {
                    try? d.write(to: URL(fileURLWithPath: String(format: "%@/f%04d.png", dir, f)))
                }
            }
            print("wrote \(dir)")
        }
    }
}
