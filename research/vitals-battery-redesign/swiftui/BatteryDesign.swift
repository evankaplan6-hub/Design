// Battery tab design study, rendered with real SwiftUI (ImageRenderer).
// Run: swiftc -parse-as-library -target arm64-apple-macosx26.0 -o /tmp/bd BatteryDesign.swift && /tmp/bd out
// Uses Vitals' own metrics: module radius 16, padding 12, gap 8, .fill.quaternary modules,
// secondary text = primary at 0.72, SF Pro Rounded figures. Glass can't be drawn here.
import SwiftUI
import Charts
import AppKit

enum Metrics { static let radius: CGFloat = 16; static let pad: CGFloat = 12; static let gap: CGFloat = 8 }
let secondary = Color.primary.opacity(0.72)

struct Reading: Identifiable { let id: Int; let hour: Double; let level: Double?; let run: Int }

struct BatteryState {
    var level: Double            // 0...100
    var limit: Double?           // charge limit, if set
    var charging: Bool
    var pluggedIn: Bool
    var headline: String         // status line
    var timeLine: String?        // "About 4 hr 10 min left"
    var summary: String          // "Up from 41% at 9:05 AM"
    var readings: [Reading]
    var mark: (hour: Double, level: Double, label: String)
    var apps: [(name: String, path: String, share: Double)]
}

// MARK: - The battery object (the moment)

struct BatteryObject: View {
    var level: Double
    var limit: Double?
    var charging: Bool
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        GeometryReader { geo in
            let capW: CGFloat = 8
            let bodyW = geo.size.width - capW - 3
            let h = geo.size.height
            let inset: CGFloat = 5
            let innerW = bodyW - inset * 2
            let innerH = h - inset * 2
            let fillW = max(28, innerW * level / 100)
            let low = level <= 10 && !charging
            let dark = scheme == .dark
            let fill: Color = low ? .red : charging ? .green : (dark ? Color(white: 0.86) : Color(white: 0.46))
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.fill.quinary)
                    .strokeBorder(Color.primary.opacity(dark ? 0.30 : 0.24), lineWidth: 2)
                    .frame(width: bodyW, height: h)
                UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 5, topTrailingRadius: 5)
                    .fill(Color.primary.opacity(dark ? 0.30 : 0.24))
                    .frame(width: capW, height: h * 0.34)
                    .offset(x: bodyW + 3, y: h * 0.33)
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(fill)
                    .frame(width: fillW, height: innerH)
                    .offset(x: inset, y: inset)
                if let limit, limit < 100, level < limit - 1 {
                    let x = inset + innerW * limit / 100
                    let notch = dark ? Color(red: 0.137, green: 0.137, blue: 0.145) : Color(red: 0.925, green: 0.925, blue: 0.933)
                    Rectangle().fill(level >= limit - 1 ? notch : Color.primary.opacity(0.45))
                        .frame(width: 2, height: innerH)
                        .offset(x: x - 1, y: inset)
                    Text("Limit").font(.caption2).foregroundStyle(secondary)
                        .fixedSize().frame(width: 40, alignment: .center)
                        .offset(x: x - 20, y: -16)
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Battery \(Int(level))%" + (limit.map { ", limit \(Int($0))%" } ?? ""))
    }
}

// MARK: - The day line (small, second in rank)

struct DayLine: View {
    var readings: [Reading]
    var limit: Double?
    var mark: (hour: Double, level: Double, label: String)
    var body: some View {
        Chart {
            if let limit {
                RuleMark(y: .value("Limit", limit))
                    .foregroundStyle(Color.primary.opacity(0.35))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 3]))
                    .annotation(position: .top, alignment: .trailing, spacing: 2) {
                        Text("\(Int(limit))%").font(.caption2).foregroundStyle(secondary)
                    }
            }
            ForEach(readings.filter { $0.level != nil }) { r in
                LineMark(x: .value("Hour", r.hour), y: .value("Level", r.level!), series: .value("Run", r.run))
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .foregroundStyle(Color.primary)
            }
        }
        .chartYScale(domain: 0...100)
        .chartYAxis(.hidden)
        .chartXScale(domain: 0...24)
        .chartXAxis {
            AxisMarks(values: [0, 12, 24]) { v in
                AxisValueLabel(anchor: v.as(Double.self) == 24 ? .topTrailing : (v.as(Double.self) == 0 ? .topLeading : .top)) {
                    Text(["Yesterday", "6 AM", "Now"][Int((v.as(Double.self) ?? 0) / 12)])
                        .font(.caption2).foregroundStyle(secondary)
                }
            }
        }
        .frame(height: 96)
    }
}

// MARK: - Tab

struct BatteryTabDesign: View {
    var s: BatteryState
    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.gap) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: 16) {
                    Text("\(Int(s.level))%")
                        .font(.system(size: 44, weight: .semibold, design: .rounded)).monospacedDigit()
                        .foregroundStyle(s.level <= 10 && !s.charging ? Color.red : Color.primary)
                        .fixedSize()
                    BatteryObject(level: s.level, limit: s.limit, charging: s.charging)
                        .frame(height: 48)
                }
                .padding(.top, 12)
                VStack(alignment: .leading, spacing: 2) {
                    Text(s.timeLine.map { "\(s.headline) · \($0)" } ?? s.headline)
                        .font(.system(size: 15, weight: .medium))
                    Text(s.summary).font(.callout).foregroundStyle(secondary)
                }
                .padding(.top, 14)
                DayLine(readings: s.readings, limit: s.limit, mark: s.mark).padding(.top, 20)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous).fill(.fill.quaternary))

            VStack(alignment: .leading, spacing: 8) {
                Text("Your apps using the most energy").font(.headline)
                ForEach(s.apps, id: \.name) { app in
                    HStack(spacing: 10) {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: app.path))
                            .resizable().frame(width: 22, height: 22)
                        Text(app.name).font(.body)
                        Spacer(minLength: 0)
                    }
                    .frame(height: 26)
                }
            }
            .padding(Metrics.pad + 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous).fill(.fill.quaternary))

            HStack(alignment: .center) {
                Label { Text("Holds 99% of its original charge") } icon: {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                }
                .font(.callout).foregroundStyle(secondary)
                Spacer(minLength: 8)
                Text("Battery Settings").font(.callout)
                    .padding(.horizontal, 12).padding(.vertical, 5)
                    .background(Capsule().fill(.fill.tertiary))
            }
            .padding(.horizontal, 4).padding(.top, 4)
        }
        .padding(12)
        .frame(width: 420, alignment: .top)
    }
}

// MARK: - Data

func readings(_ f: (Double) -> Double?) -> [Reading] {
    var out: [Reading] = []; var run = 0; var wasNil = false
    for i in 0...96 { let h = Double(i) / 4; let v = f(h)
        if v == nil { wasNil = true } else if wasNil { run += 1; wasNil = false }
        out.append(Reading(id: i, hour: h, level: v, run: run)) }
    return out
}

let plugged = BatteryState(
    level: 95, limit: 95, charging: false, pluggedIn: true,
    headline: "Charged to 95% Limit", timeLine: nil, summary: "Up from 41% at 9:05 AM",
    readings: readings { h in
        if h < 5 { return 70 - h * 2 }; if h < 13 { return 60 - (h - 5) * 0.25 }
        if h < 15 { return 58 - (h - 13) * 8.5 }; if h < 17.2 { return 41 + (h - 15) * 24.5 }; return 95 },
    mark: (15, 41, "Plugged in 9:05 AM"),
    apps: [("Google Chrome", "/Applications/Google Chrome.app", 1.0), ("Claude", "/Applications/Claude.app", 0.42), ("Spotify", "/Applications/Spotify.app", 0.18)])

let onBattery = BatteryState(
    level: 62, limit: 95, charging: false, pluggedIn: false,
    headline: "On battery", timeLine: "About 4 hr 10 min left", summary: "Down 33% since 2:10 PM",
    readings: readings { h in h < 20.17 ? 95 : 95 - (h - 20.17) * 8.6 },
    mark: (20.17, 95, "Unplugged 2:10 PM"),
    apps: [("Google Chrome", "/Applications/Google Chrome.app", 1.0), ("Claude", "/Applications/Claude.app", 0.42), ("Cursor", "/Applications/Cursor.app", 0.18)])

let charging = BatteryState(
    level: 58, limit: 95, charging: true, pluggedIn: true,
    headline: "Charging to 95% Limit", timeLine: "Full in 45 min", summary: "Up from 22% at 4:40 PM",
    readings: readings { h in h < 22.67 ? max(22, 80 - h * 2.5 + 1.6 * sin(h * 1.3) + (h > 8 && h < 14 ? -(h - 8) * 0.6 : 0)) : 22 + (h - 22.67) * 27 },
    mark: (22.67, 22, "Plugged in 4:40 PM"),
    apps: [("Google Chrome", "/Applications/Google Chrome.app", 1.0), ("Spotify", "/Applications/Spotify.app", 0.42), ("Safari", "/Applications/Safari.app", 0.18)])

@main struct Render {
    @MainActor static func main() {
        let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
        for (name, state) in [("plugged", plugged), ("onbattery", onBattery), ("charging", charging)] {
            for scheme in [ColorScheme.light, .dark] {
                let bg = scheme == .dark ? Color(red: 0.137, green: 0.137, blue: 0.145) : Color(red: 0.925, green: 0.925, blue: 0.933)
                let view = BatteryTabDesign(s: state).background(bg).environment(\.colorScheme, scheme)
                NSApplication.shared.appearance = NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)
                var png: Data?
                (NSApplication.shared.appearance ?? NSAppearance.currentDrawing()).performAsCurrentDrawingAppearance {
                    let r = ImageRenderer(content: view); r.scale = 2; r.isOpaque = true
                    if let cg = r.cgImage, let space = CGColorSpace(name: CGColorSpace.sRGB),
                       let ctx = CGContext(data: nil, width: cg.width, height: cg.height, bitsPerComponent: 8, bytesPerRow: 0, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
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
