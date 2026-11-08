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
var morph: CGFloat = 0, vel: CGFloat = 0, speed: CGFloat = 0, sv: CGFloat = 0, spin: CGFloat = 0, goal: CGFloat = 0, target: CGFloat = 0
let start = Date(); var last = start, caOn = false, caDone = false, appliedRate: CGFloat = 0, reversed = false, shots = Set<String>()
let rotor = CALayer(), sharp = CALayer(), blurred = CALayer(); var mark: (cpu: Double, server: Double, t: Double)? = nil; var idle: (cpu: Double, server: Double, t: Double)? = nil; var idleResult = 0.0
var timer: Timer?
func schedule(_ hz: Double) { timer?.invalidate(); let t = Timer(timeInterval: 1 / hz, repeats: true) { _ in tick() }; RunLoop.main.add(t, forMode: .common); timer = t }
var currentHz = 60.0
func setHz(_ hz: Double) { if hz != currentHz { currentHz = hz; schedule(hz) } }
func startCA() {
    guard let b = item.button else { return }
    let dark = b.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    print("menu bar appearance dark:", dark, "layer flipped:", b.layer?.contentsAreFlipped() ?? false, b.isFlipped)
    let color: NSColor = dark ? .white : .black
    b.wantsLayer = true; let size = CGSize(width: 22, height: 22)
    rotor.bounds = CGRect(origin: .zero, size: size); rotor.position = CGPoint(x: b.bounds.midX, y: b.bounds.midY); rotor.contentsScale = 2
    for (l, blur) in [(sharp, CGFloat(0)), (blurred, CGFloat(14))] { l.frame = rotor.bounds; l.contentsScale = 2; l.contents = rotorImage(blur: blur, color: color); rotor.addSublayer(l) }
    rotor.setValue(-spin * .pi / 180, forKeyPath: "transform.rotation.z")
    b.layer?.addSublayer(rotor); b.image = image(1, spin: 0, blur: 0, rotor: false)
    let a = CABasicAnimation(keyPath: "transform.rotation.z"); a.byValue = -2 * CGFloat.pi; a.duration = 1; a.repeatCount = .infinity; a.isCumulative = true; rotor.add(a, forKey: "spin")
    caOn = true
}
func setRate(_ r: CGFloat) { let now = CACurrentMediaTime(); let off = rotor.convertTime(now, from: nil); rotor.timeOffset = off; rotor.beginTime = now; rotor.speed = Float(r); appliedRate = r }
func stopCA() { let rad = (rotor.presentation()?.value(forKeyPath: "transform.rotation.z") as? CGFloat) ?? 0; var a = (-rad * 180 / .pi).truncatingRemainder(dividingBy: 72); if a > 36 { a -= 72 }; if a < -36 { a += 72 }; spin = a; rotor.removeAllAnimations(); rotor.removeFromSuperlayer(); caOn = false; caDone = true; reversed = true }
func shoot(_ name: String) {
    guard !shots.contains(name) else { return }; shots.insert(name)
    let p = Process(); p.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture"); p.arguments = ["-x", "\(dir)/full-\(name).png"]; try? p.run()
}
func tick() {
    let now = Date(), el = now.timeIntervalSince(start); var left = CGFloat(min(0.6, now.timeIntervalSince(last))); last = now
    let rpm: CGFloat = el < 1.5 ? 0 : el < 4 ? 2350 : el < 6.5 ? 4600 : el < 10 ? 6300 : 0
    target = rpm / 2620; goal = el >= 1.5 && el < 13 ? 1 : 0
    if goal == 0 && caOn { stopCA() }
    while left > 0 { let dt = min(left, 1 / 120); left -= dt
        let w = 2 * .pi / 0.85 as CGFloat; vel += (-2 * w * vel - w * w * (morph - goal)) * dt; morph = clamp(morph + vel * dt)
        let ws = 2 * .pi / 1.1 as CGFloat; sv += (-2 * ws * sv - ws * ws * (speed - target)) * dt; speed = max(0, speed + sv * dt); if !caOn { spin += speed * 360 * dt } }
    if !caOn && !caDone && morph > 0.9995 && goal == 1 { startCA() }
    if caOn {
        if abs(speed - appliedRate) > 0.004 { setRate(speed); let f = Float(min(1, speed / 2.5)); CATransaction.begin(); CATransaction.setDisableActions(true); blurred.opacity = f; sharp.opacity = 1 - f; CATransaction.commit() }
        setHz(abs(speed - target) < 0.004 && abs(sv) < 0.01 ? 2 : 20)
    } else { setHz(morph < 0.0005 && goal == 0 ? 10 : 60); item.button?.image = image(morph, spin: spin, blur: speed * 5.6 * sm(0.6, 1, morph)) }
    if idle == nil && el > 0.2 { idle = (cpu(), serverCPU(), el) }
    if let i = idle, idleResult == 0, el > 1.4 { idleResult = (serverCPU() - i.server) / (el - i.t); print(String(format: "idle: WindowServer %.1f%%", idleResult * 100)) }
    if el > 0.6 { shoot("rest") }; if morph > 0.42 { shoot("mid") }; if el > 3.7 { shoot("low") }; if el > 9 { shoot("spin") }
    if mark == nil && el > 7.5 { mark = (cpu(), serverCPU(), el) }
    if let m = mark, !shots.contains("cpu"), el > 12 { shots.insert("cpu"); let d = el - m.t; print(String(format: "spinning via Core Animation: app %.2f%%, WindowServer %.1f%% (window %.1fs)", (cpu() - m.cpu) / d * 100, (serverCPU() - m.server) / d * 100, d)) }
    if el > 16.5 { exit(0) }
}
schedule(60)
app.run()
