import AppKit

// Throwaway test: plays the morph in the real menu bar on a made-up speed timeline, then quits.
let STROKE: CGFloat = 1.175, RING: CGFloat = 8.1, U: CGFloat = 0.9
typealias P = CGPoint
func clamp(_ x: CGFloat) -> CGFloat { min(1, max(0, x)) }
func sm(_ a: CGFloat, _ b: CGFloat, _ x: CGFloat) -> CGFloat { let t = clamp((x - a) / (b - a)); return t * t * t * (t * (t * 6 - 15) + 10) }
func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }
func lerp(_ a: P, _ b: P, _ t: CGFloat) -> P { P(x: lerp(a.x, b.x, t), y: lerp(a.y, b.y, t)) }
func pol(_ r: CGFloat, _ deg: CGFloat) -> P { let t = deg * .pi / 180; return P(x: r * sin(t), y: r * cos(t)) }
func cwRot(_ p: P, _ deg: CGFloat) -> P { let t = -deg * .pi / 180; return P(x: p.x * cos(t) - p.y * sin(t), y: p.x * sin(t) + p.y * cos(t)) }
func dist(_ a: P, _ b: P) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }
func ang(_ a: P, _ b: P) -> CGFloat { atan2(b.y - a.y, b.x - a.x) }
func quad(_ a: P, _ c: P, _ b: P, _ t: CGFloat) -> P { lerp(lerp(a, c, t), lerp(c, b, t), t) }
let V: [P] = [P(x: -6.575, y: -0.9), P(x: -3.4, y: -0.875), P(x: -1.925, y: 5.775), P(x: 0.325, y: -6.625), P(x: 2.475, y: 2.75), P(x: 3.425, y: -0.875), P(x: 6.2, y: -0.9)]
let SPLIT = lerp(V[2], V[3], 0.5)
let strokes: [(P, P)] = [(V[1], V[2]), (V[2], SPLIT), (SPLIT, V[3]), (V[3], V[4]), (V[4], V[5])]
let PHASE: CGFloat = 27, PERM = [4, 3, 2, 0, 1], FLIP = [false, true, false, false, true]
let rin: CGFloat = 2.9 * U, R: CGFloat = 7.3 * U, sw: CGFloat = 38, W: CGFloat = 30, root: CGFloat = 18, bow: CGFloat = 14, mid = (rin + R) / 2
let nCap = 6, nSide = 16, nTip = 8
var blade: [P] = []
for i in 0..<nCap { blade.append(pol(rin, root * (1 - CGFloat(i) / CGFloat(nCap)))) }
for i in 0..<nSide { blade.append(quad(pol(rin, 0), pol(mid, sw * 0.5 - bow), pol(R, sw), CGFloat(i) / CGFloat(nSide))) }
for i in 0..<nTip { blade.append(pol(R, sw + W * CGFloat(i) / CGFloat(nTip))) }
for i in 0..<nSide { blade.append(quad(pol(R, sw + W), pol(mid, root + (sw + W - root) * 0.5 - bow), pol(rin, root), CGFloat(i) / CGFloat(nSide))) }
let bladeRoot = pol(rin, root / 2), bladeTip = pol(R, sw + W / 2), bladeAxis = ang(bladeRoot, bladeTip)
func toLocal(_ p: P, _ o: P, _ a: CGFloat) -> P { let x = p.x - o.x, y = p.y - o.y; return P(x: x * cos(-a) - y * sin(-a), y: x * sin(-a) + y * cos(-a)) }
func fromLocal(_ p: P, _ o: P, _ a: CGFloat) -> P { P(x: o.x + p.x * cos(a) - p.y * sin(a), y: o.y + p.x * sin(a) + p.y * cos(a)) }
let bladeLocal = blade.map { toLocal($0, bladeRoot, bladeAxis) }
let lead: CGFloat = bladeLocal[nCap + nSide / 2].y > 0 ? 1 : -1
func capsule(_ L: CGFloat) -> [P] {
    let r = STROKE / 2, s = lead; var o: [P] = []
    for i in 0..<nCap { let a = .pi / 2 + .pi * (1 - CGFloat(i) / CGFloat(nCap)); o.append(P(x: r * cos(a), y: s * r * sin(a))) }
    for i in 0..<nSide { o.append(P(x: L * CGFloat(i) / CGFloat(nSide), y: s * r)) }
    for i in 0..<nTip { let a = .pi / 2 - .pi * CGFloat(i) / CGFloat(nTip); o.append(P(x: L + r * cos(a), y: s * r * sin(a))) }
    for i in 0..<nSide { o.append(P(x: L * (1 - CGFloat(i) / CGFloat(nSide)), y: -s * r)) }
    return o
}
func lerpAngle(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { var d = (b - a).truncatingRemainder(dividingBy: 2 * .pi); if d > .pi { d -= 2 * .pi }; if d < -.pi { d += 2 * .pi }; return a + d * t }
func bladePoly(_ slot: Int, _ t: CGFloat) -> [P] {
    let s = PERM[slot], f = FLIP[slot]
    let from = f ? strokes[s].1 : strokes[s].0, to = f ? strokes[s].0 : strokes[s].1
    let cap = capsule(dist(from, to)), a0 = ang(from, to), rot = PHASE + CGFloat(slot) * 72
    let target = cwRot(bladeRoot, rot), axis = bladeAxis - rot * .pi / 180
    let m = sm(0, 0.9, t), shape = sm(0.08, 0.8, t), o = lerp(from, target, m), a = lerpAngle(a0, axis, m)
    return zip(cap, bladeLocal).map { fromLocal(lerp($0, $1, shape), o, a) }
}
func tails(_ t: CGFloat) -> ([P], [P]) {
    let m = sm(0.04, 0.94, t), n = 40
    func path(_ a: P, _ b: P, _ th0: CGFloat, _ th1: CGFloat) -> [P] { (0...n).map { i in let k = CGFloat(i) / CGFloat(n), p = lerp(a, b, k); var th = atan2(p.x, p.y) * 180 / .pi; if th < 0 { th += 360 }; return pol(lerp(hypot(p.x, p.y), RING, m), lerp(th, lerp(th0, th1, k), m)) } }
    return (path(V[0], V[1], 360, 180), path(V[6], V[5], 0, 180))
}
func image(_ t: CGFloat, spin: CGFloat, blur: CGFloat, rotor: Bool = true) -> NSImage {
    let polys = (0..<5).map { bladePoly($0, t) }, (l, r) = tails(t), w = sm(0.3, 1, t)
    let layers = blur > 0.5 ? 8 : 1
    let im = NSImage(size: NSSize(width: 22, height: 22), flipped: false) { _ in
        guard let c = NSGraphicsContext.current?.cgContext else { return false }
        c.translateBy(x: 11, y: 11); c.setStrokeColor(NSColor.black.cgColor); c.setLineWidth(STROKE); c.setLineCap(.round); c.setLineJoin(.round)
        for line in [l, r] { c.move(to: line[0]); for p in line.dropFirst() { c.addLine(to: p) }; c.strokePath() }
        c.saveGState(); c.beginTransparencyLayer(auxiliaryInfo: nil); c.setBlendMode(layers > 1 ? .plusLighter : .normal)
        c.setFillColor(NSColor.black.withAlphaComponent(1 / CGFloat(layers)).cgColor)
        for j in 0..<layers {
            c.saveGState(); c.rotate(by: -(spin * w - blur * CGFloat(j) / max(1, CGFloat(layers - 1))) * .pi / 180)
            if rotor { for q in polys { c.move(to: q[0]); for p in q.dropFirst() { c.addLine(to: p) }; c.closePath(); c.fillPath() } }
            c.restoreGState()
        }
        c.endTransparencyLayer(); c.restoreGState()
        let g = sm(0.25, 0.85, t), hr = 1.8 * g, hc = lerp(SPLIT, .zero, g)
        c.setFillColor(NSColor.black.cgColor); if hr > 0.01 { c.fillEllipse(in: CGRect(x: hc.x - hr, y: hc.y - hr, width: 2 * hr, height: 2 * hr)) }
        return true
    }
    im.isTemplate = true; return im
}
func cpu() -> Double { var u = rusage(); getrusage(RUSAGE_SELF, &u); return Double(u.ru_utime.tv_sec + u.ru_stime.tv_sec) + Double(u.ru_utime.tv_usec + u.ru_stime.tv_usec) / 1e6 }
func rotorImage(blur: CGFloat, color: NSColor) -> NSImage {
    let polys = (0..<5).map { bladePoly($0, 1) }, layers = blur > 0.5 ? 8 : 1
    return NSImage(size: NSSize(width: 22, height: 22), flipped: false) { _ in
        guard let c = NSGraphicsContext.current?.cgContext else { return false }
        c.translateBy(x: 11, y: 11); c.setBlendMode(layers > 1 ? .plusLighter : .normal)
        c.setFillColor(color.withAlphaComponent(1 / CGFloat(layers)).cgColor)
        for j in 0..<layers { c.saveGState(); c.rotate(by: blur * CGFloat(j) / max(1, CGFloat(layers - 1)) * .pi / 180)
            for q in polys { c.move(to: q[0]); for p in q.dropFirst() { c.addLine(to: p) }; c.closePath(); c.fillPath() }
            c.restoreGState() }
        return true
    }
}
func serverCPU() -> Double {
    let p = Process(), pipe = Pipe(); p.executableURL = URL(fileURLWithPath: "/bin/ps"); p.arguments = ["-axo", "time=,comm="]; p.standardOutput = pipe; try? p.run()
    let data = pipe.fileHandleForReading.readDataToEndOfFile(); p.waitUntilExit()
    for l in String(decoding: data, as: UTF8.self).split(separator: "\n") where l.hasSuffix("WindowServer") {
        let f = l.split(separator: " ")[0].split(separator: ":").map { Double($0) ?? 0 }; return f.reduce(0) { $0 * 60 + $1 }
    }
    return 0
}
let dir = CommandLine.arguments[1]
let app = NSApplication.shared; app.setActivationPolicy(.accessory)
let item = NSStatusBar.system.statusItem(withLength: 26)
let b = item.button!
func wait(_ s: Double) { RunLoop.current.run(until: Date().addingTimeInterval(s)) }
struct Gray { var w: Int; var h: Int; var v: [UInt8] }
var shots: [String: Gray] = [:]
func shoot(_ name: String) {
    wait(0.4)
    let path = "\(dir)/\(name).png"
    let p = Process(); p.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture"); p.arguments = ["-x", path]; try? p.run(); p.waitUntilExit()
    guard let rep = NSBitmapImageRep(data: (try? Data(contentsOf: URL(fileURLWithPath: path))) ?? Data()), let im = rep.cgImage, let wnd = b.window else { print("capture failed", name); return }
    let px = Int(wnd.frame.midX * 2), w = 120, h = 56
    let crop = im.cropping(to: CGRect(x: px - w / 2, y: 0, width: w, height: h))!
    let c = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)!
    c.draw(crop, in: CGRect(x: 0, y: 0, width: w, height: h))
    shots[name] = Gray(w: w, h: h, v: Array(UnsafeBufferPointer(start: c.data!.assumingMemoryBound(to: UInt8.self), count: w * h)))
    try? FileManager.default.removeItem(atPath: path)
}
func diff(_ a: String, _ c: String) -> (Double, Int) {
    guard let x = shots[a], let y = shots[c] else { return (-1, 0) }
    var best = Double.infinity, bx = 0
    for dx in -24...24 { var s = 0.0; var n = 0
        for yy in 0..<x.h { for xx in max(0, -dx)..<min(x.w, x.w - dx) { s += abs(Double(x.v[yy * x.w + xx]) - Double(y.v[yy * x.w + xx + dx])); n += 1 } }
        s /= Double(n); if s < best { best = s; bx = dx } }
    return (best, bx)
}
func peak(_ n: String) -> Int { Int(shots[n]?.v.max() ?? 0) }
func cmp(_ label: String, _ a: String, _ c: String) { let d = diff(a, c); print(String(format: "%@: difference %.2f (0 is identical), shift %d px, brightest %d vs %d", label, d.0, d.1, peak(a), peak(c))) }
func setRot(_ l: CALayer, _ deg: CGFloat) { CATransaction.begin(); CATransaction.setDisableActions(true); l.transform = CATransform3DMakeRotation(deg * .pi / 180, 0, 0, 1); CATransaction.commit() }
wait(0.6)
b.image = image(1, spin: 10, blur: 0); shoot("img10")
b.image = image(1, spin: 28, blur: 0); shoot("img28")
b.image = image(1, spin: 0, blur: 0, rotor: false)
let tmpl = rotorImage(blur: 0, color: .black); tmpl.isTemplate = true
let iv = NSImageView(frame: NSRect(x: (b.bounds.width - 22) / 2, y: (b.bounds.height - 22) / 2, width: 22, height: 22)); iv.image = tmpl; iv.imageScaling = .scaleNone; iv.wantsLayer = true
b.addSubview(iv); wait(0.1)
let vl = iv.layer!; let f = vl.frame; vl.anchorPoint = CGPoint(x: 0.5, y: 0.5); vl.position = CGPoint(x: f.midX, y: f.midY)
setRot(vl, 10); shoot("pos10"); setRot(vl, 28); shoot("pos28"); setRot(vl, -28); shoot("neg28")
setRot(vl, 0)
// The real animation, paused at known moments.
let a = CABasicAnimation(keyPath: "transform.rotation.z"); a.byValue = 2 * CGFloat.pi; a.duration = 1; a.repeatCount = .infinity; a.isCumulative = true
vl.speed = 0; vl.timeOffset = 0; vl.beginTime = 0; vl.add(a, forKey: "spin")
vl.timeOffset = 10.0 / 360; shoot("anim10"); vl.timeOffset = 28.0 / 360; shoot("anim28")
// Run it live for real CPU numbers, then confirm the layer is still centered.
let start = cpu(); vl.timeOffset = 0; vl.beginTime = CACurrentMediaTime(); vl.speed = 2.4
wait(4)
print(String(format: "live spin in a template view: app %.2f%% of one core", (cpu() - start) / 4 * 100))
print("layer still animating:", vl.animation(forKey: "spin") != nil, "position", vl.position, "bounds", vl.bounds.size)
vl.speed = 0; vl.timeOffset = 28.0 / 360; vl.beginTime = 0; shoot("after28")
print("---")
cmp("template view +10 vs drawn 10", "img10", "pos10")
cmp("template view +28 vs drawn 28", "img28", "pos28")
cmp("template view -28 vs drawn 28 (wrong way)", "img28", "neg28")
cmp("animation paused at 10 vs drawn 10", "img10", "anim10")
cmp("animation paused at 28 vs drawn 28", "img28", "anim28")
cmp("after 4s live, paused at 28 vs drawn 28", "img28", "after28")
exit(0)
