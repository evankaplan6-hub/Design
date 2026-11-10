import AppKit

let scale = 6, side = 22 * scale
func makeRep() -> NSBitmapImageRep {
    NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: side * 4, bitsPerPixel: 32)!
}
func alpha(_ draw: (CGContext) -> Void) -> [UInt8] {
    let rep = makeRep(); NSGraphicsContext.saveGraphicsState()
    let g = NSGraphicsContext(bitmapImageRep: rep)!; NSGraphicsContext.current = g
    let c = g.cgContext; c.scaleBy(x: CGFloat(scale), y: CGFloat(scale)); draw(c); g.flushGraphics(); NSGraphicsContext.restoreGraphicsState()
    let d = rep.bitmapData!; return (0..<side * side).map { d[$0 * 4 + 3] }
}
let cfg = NSImage.SymbolConfiguration(pointSize: 14, weight: .semibold).applying(NSImage.SymbolConfiguration(paletteColors: [.black]))
let sym = NSImage(systemSymbolName: "waveform.path.ecg", accessibilityDescription: nil)!.withSymbolConfiguration(cfg)!
print("symbol size", sym.size)
let target = alpha { _ in sym.draw(in: NSRect(x: 11 - sym.size.width / 2, y: 11 - sym.size.height / 2, width: sym.size.width, height: sym.size.height)) }
func drawLine(_ c: CGContext, _ p: [CGFloat]) {
    c.translateBy(x: 11, y: 11); c.setStrokeColor(NSColor.black.cgColor); c.setLineWidth(p[14]); c.setLineCap(.round); c.setLineJoin(.round)
    c.move(to: CGPoint(x: p[0], y: p[1])); for i in 1..<7 { c.addLine(to: CGPoint(x: p[i * 2], y: p[i * 2 + 1])) }; c.strokePath()
}
func score(_ p: [CGFloat]) -> Double { let a = alpha { drawLine($0, p) }; var s = 0.0; for i in a.indices { let d = Double(a[i]) - Double(target[i]); s += d * d }; return s / Double(a.count) }
var p: [CGFloat] = [-6.5,-0.85,-3.5,-0.85,-1.85,5.75,0.4,-6.5,2.55,2.75,3.75,-0.85,6.3,-0.85,1.15]
let start = score(p); var best = start
print("starting difference", String(format: "%.1f", start))
for step in [0.2, 0.1, 0.05, 0.025] as [CGFloat] {
    var improved = true; var rounds = 0
    while improved && rounds < 12 { improved = false; rounds += 1
        for i in p.indices { for dir in [step, -step] { var q = p; q[i] += dir; let s = score(q); if s < best { best = s; p = q; improved = true; break } } }
    }
}
print("fitted difference", String(format: "%.1f", best))
print("vertices", (0..<7).map { String(format: "(%.3f, %.3f)", p[$0 * 2], p[$0 * 2 + 1]) }.joined(separator: " "))
print("line width", String(format: "%.3f", p[14]))
// Show real symbol (white), fitted line (red channel difference) at real size and enlarged.
let a = alpha { drawLine($0, p) }
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: side * 4, bitsPerPixel: 32)!
let d = rep.bitmapData!
for i in 0..<side * side { d[i*4] = target[i]; d[i*4+1] = a[i]; d[i*4+2] = a[i]; d[i*4+3] = 255 }
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
