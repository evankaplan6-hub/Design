import AppKit

let bg = NSColor(srgbRed: 0.09, green: 0.094, blue: 0.106, alpha: 1)
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
func polarLerp(_ a: P, _ b: P, _ t: CGFloat) -> P {
    let ra = hypot(a.x, a.y), rb = hypot(b.x, b.y), ta = atan2(a.x, a.y), tb = atan2(b.x, b.y)
    let th = lerpAngle(ta, tb, t), r = lerp(ra, rb, t); return P(x: r * sin(th), y: r * cos(th))
}
func permutations(_ a: [Int]) -> [[Int]] { if a.count < 2 { return [a] }; return a.indices.flatMap { i -> [[Int]] in var r = a; let x = r.remove(at: i); return permutations(r).map { [x] + $0 } } }

struct Cand { var phase: CGFloat; var perm: [Int]; var flip: [Bool]; var cost: CGFloat; var polar = false; var stagger: CGFloat = 0.015; var byTravel = false; var early = false }
func delays(_ c: Cand) -> [CGFloat] {
    guard c.byTravel else { return (0..<5).map { CGFloat($0) * c.stagger } }
    let travel: [CGFloat] = (0..<5).map { slot in let s = c.perm[slot], rot = c.phase + CGFloat(slot) * 72; let from = c.flip[slot] ? strokes[s].1 : strokes[s].0; return dist(from, cwRot(bladeRoot, rot)) }
    let order = travel.indices.sorted { travel[$0] < travel[$1] }
    var d = [CGFloat](repeating: 0, count: 5); for (rank, i) in order.enumerated() { d[i] = CGFloat(rank) * c.stagger }; return d
}
func poly(_ c: Cand, _ slot: Int, _ t: CGFloat, _ delay: CGFloat) -> [P] {
    let s = c.perm[slot], f = c.flip[slot]
    let from = f ? strokes[s].1 : strokes[s].0, to = f ? strokes[s].0 : strokes[s].1
    let cap = capsule(dist(from, to)), a0 = ang(from, to), rot = c.phase + CGFloat(slot) * 72
    let target = cwRot(bladeRoot, rot), axis = bladeAxis - rot * .pi / 180
    let end = min(1, 0.9 + delay), m = sm(delay, end, t), shape = c.early ? sm(0.08, 0.8, t) : sm(0.2, 1, t)
    let o = c.polar ? polarLerp(from, target, m) : lerp(from, target, m), a = lerpAngle(a0, axis, m)
    return zip(cap, bladeLocal).map { fromLocal(lerp($0, $1, shape), o, a) }
}
func inside(_ pt: P, _ poly: [P]) -> Bool {
    var c = false; var j = poly.count - 1
    for i in poly.indices { let a = poly[i], b = poly[j]; if (a.y > pt.y) != (b.y > pt.y), pt.x < (b.x - a.x) * (pt.y - a.y) / (b.y - a.y) + a.x { c.toggle() }; j = i }
    return c
}
// Overlap between blades through the middle of the morph, in square points.
func overlap(_ c: Cand) -> CGFloat {
    let n = 56, step = 18 / CGFloat(n), ds = delays(c); var total: CGFloat = 0; var samples = 0
    for k in 0...8 {
        let t = 0.18 + 0.62 * CGFloat(k) / 8; let polys = (0..<5).map { poly(c, $0, t, ds[$0]) }
        var over = 0
        for iy in 0..<n { for ix in 0..<n {
            let p = P(x: -9 + (CGFloat(ix) + 0.5) * step, y: -9 + (CGFloat(iy) + 0.5) * step); var hits = 0
            for q in polys where inside(p, q) { hits += 1; if hits > 1 { break } }
            if hits > 1 { over += 1 }
        } }
        total += CGFloat(over) * step * step; samples += 1
    }
    return total / CGFloat(samples)
}
var pool: [Cand] = []
for ph in stride(from: CGFloat(0), to: 72, by: 3) { for perm in permutations([0,1,2,3,4]) {
    var cost: CGFloat = 0; var flips: [Bool] = []
    for (slot, s) in perm.enumerated() {
        let a = ph + CGFloat(slot) * 72, br = cwRot(bladeRoot, a), bt = cwRot(bladeTip, a)
        let c1 = pow(dist(strokes[s].0, br), 2) + pow(dist(strokes[s].1, bt), 2), c2 = pow(dist(strokes[s].1, br), 2) + pow(dist(strokes[s].0, bt), 2)
        cost += min(c1, c2); flips.append(c2 < c1)
    }
    pool.append(Cand(phase: ph, perm: perm, flip: flips, cost: cost))
} }
pool.sort { $0.cost < $1.cost }
let current = Cand(phase: 27, perm: [4,3,2,0,1], flip: [false,true,false,false,true], cost: 107.2)
print("current overlap", String(format: "%.2f", overlap(current)))
var scored: [(Cand, CGFloat)] = []
for base in pool.prefix(24) { for polar in [false, true] { for st: CGFloat in [0, 0.03, 0.07] { for byT in [false, true] { for early in [false, true] {
    if st == 0 && byT { continue }
    var c = base; c.polar = polar; c.stagger = st; c.byTravel = byT; c.early = early
    scored.append((c, overlap(c)))
} } } } }
// Reward low overlap, then short travel.
scored.sort { ($0.1 + $0.0.cost * 0.03) < ($1.1 + $1.0.cost * 0.03) }
for (c, o) in scored.prefix(6) { print("overlap", String(format: "%.2f", o), "travel", Int(c.cost), "phase", c.phase, c.perm, c.flip.map { $0 ? 1 : 0 }, c.polar ? "polar" : "straight", "stagger", c.stagger, c.byTravel ? "byTravel" : "bySlot", c.early ? "early" : "late") }
let best = scored[0].0
func tails(_ t: CGFloat) -> ([P], [P]) {
    let m = sm(0.04, 0.94, t), n = 40
    func path(_ a: P, _ b: P, _ th0: CGFloat, _ th1: CGFloat) -> [P] { (0...n).map { i in let k = CGFloat(i) / CGFloat(n), p = lerp(a, b, k); var th = atan2(p.x, p.y) * 180 / .pi; if th < 0 { th += 360 }; return pol(lerp(hypot(p.x, p.y), RING, m), lerp(th, lerp(th0, th1, k), m)) } }
    return (path(V[0], V[1], 360, 180), path(V[6], V[5], 0, 180))
}
func draw(_ c: CGContext, _ d: Cand, _ t: CGFloat) {
    c.setStrokeColor(NSColor.white.cgColor); c.setFillColor(NSColor.white.cgColor); c.setLineWidth(STROKE); c.setLineCap(.round); c.setLineJoin(.round)
    let (l, r) = tails(t); for line in [l, r] { c.move(to: line[0]); for p in line.dropFirst() { c.addLine(to: p) }; c.strokePath() }
    let ds = delays(d)
    for s in 0..<5 { let q = poly(d, s, t, ds[s]); c.move(to: q[0]); for p in q.dropFirst() { c.addLine(to: p) }; c.closePath(); c.fillPath() }
    let g = sm(0.25, 0.85, t), hr = 1.8 * g, hc = lerp(SPLIT, .zero, g); if hr > 0.01 { c.fillEllipse(in: CGRect(x: hc.x - hr, y: hc.y - hr, width: 2 * hr, height: 2 * hr)) }
}
func render(_ wPt: Int, _ hPt: Int, scale: Int, _ body: (CGContext) -> Void) -> CGImage {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: wPt * scale, pixelsHigh: hPt * scale, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState(); let g = NSGraphicsContext(bitmapImageRep: rep)!; NSGraphicsContext.current = g
    let c = g.cgContext; c.scaleBy(x: CGFloat(scale), y: CGFloat(scale)); c.setFillColor(bg.cgColor); c.fill(CGRect(x: 0, y: 0, width: wPt, height: hPt))
    body(c); g.flushGraphics(); NSGraphicsContext.restoreGraphicsState(); return rep.cgImage!
}
let rows = [current] + scored.prefix(3).map { $0.0 }, frames = 11, cell = 100, rowH = 150
let sheet = render(frames * cell, rowH * rows.count, scale: 1) { c in
    for (v, d) in rows.enumerated() { let y = rowH * (rows.count - v - 1)
        for f in 0..<frames { let t = CGFloat(f) / CGFloat(frames - 1)
            let tile = render(20, 20, scale: 2) { x in x.translateBy(x: 10, y: 10); draw(x, d, t) }
            c.interpolationQuality = .none
            c.draw(tile, in: CGRect(x: f * cell + 30, y: y + 6, width: 40, height: 40)); c.draw(tile, in: CGRect(x: f * cell + 2, y: y + 50, width: 96, height: 96))
        } }
}
try! NSBitmapImageRep(cgImage: sheet).representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
print("ok")
