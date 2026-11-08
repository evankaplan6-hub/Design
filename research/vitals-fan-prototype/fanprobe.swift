import Foundation
import IOKit

// Read-only probe of AppleSMC fan keys. Writes nothing to the SMC.
struct Vers { var major: UInt8 = 0, minor: UInt8 = 0, build: UInt8 = 0, reserved: UInt8 = 0; var release: UInt16 = 0 }
struct LimitData { var version: UInt16 = 0, length: UInt16 = 0; var cpu: UInt32 = 0, gpu: UInt32 = 0, mem: UInt32 = 0 }
struct KeyInfo { var dataSize: UInt32 = 0; var dataType: UInt32 = 0; var attr: UInt8 = 0; var pad0: UInt8 = 0; var pad1: UInt8 = 0; var pad2: UInt8 = 0 }
typealias Bytes32 = (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8)
struct Param {
    var key: UInt32 = 0; var vers = Vers(); var limit = LimitData(); var info = KeyInfo()
    var result: UInt8 = 0, status: UInt8 = 0, data8: UInt8 = 0; var data32: UInt32 = 0
    var bytes: Bytes32 = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
}
func fcc(_ s: String) -> UInt32 { s.utf8.reduce(0) { ($0 << 8) | UInt32($1) } }
func str(_ v: UInt32) -> String { String(bytes: [24,16,8,0].map { UInt8((v >> $0) & 255) }, encoding: .ascii) ?? "?" }

let svc = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
guard svc != 0 else { print("no AppleSMC service"); exit(1) }
var conn: io_connect_t = 0
let openResult = IOServiceOpen(svc, mach_task_self_, 0, &conn)
print("open:", openResult == kIOReturnSuccess ? "ok, no admin needed" : "failed \(openResult)")
guard openResult == kIOReturnSuccess else { exit(1) }

func call(_ i: inout Param) -> kern_return_t {
    var o = Param(); var size = MemoryLayout<Param>.stride
    let r = IOConnectCallStructMethod(conn, 2, &i, MemoryLayout<Param>.stride, &o, &size)
    i = o; return r
}
func read(_ key: String) -> (type: String, bytes: [UInt8])? {
    var p = Param(); p.key = fcc(key); p.data8 = 9
    guard call(&p) == kIOReturnSuccess, p.result == 0 else { return nil }
    let size = p.info.dataSize, type = p.info.dataType
    var q = Param(); q.key = fcc(key); q.info.dataSize = size; q.data8 = 5
    guard call(&q) == kIOReturnSuccess, q.result == 0 else { return nil }
    let b = withUnsafeBytes(of: q.bytes) { Array($0.prefix(Int(size))) }
    return (str(type), b)
}
func value(_ r: (type: String, bytes: [UInt8])) -> String {
    switch r.type {
    case "flt ": return String(r.bytes.withUnsafeBytes { $0.loadUnaligned(as: Float.self) })
    case "fpe2": return String(Double((UInt16(r.bytes[0]) << 8) | UInt16(r.bytes[1])) / 4)
    default: return r.bytes.map { String($0) }.joined(separator: ",")
    }
}
let samples = CommandLine.arguments.count > 1 ? Int(CommandLine.arguments[1]) ?? 1 : 1
for key in ["FNum", "F0Mn", "F0Mx", "F0Tg", "F0Md", "F0Sf", "F1Ac"] {
    if let r = read(key) { print(key, "[\(r.type)]", value(r)) } else { print(key, "not present") }
}
let start = Date()
for _ in 0..<samples {
    let t = Date()
    if let r = read("F0Ac") { print("F0Ac [\(r.type)]", value(r), String(format: "read took %.2f ms", Date().timeIntervalSince(t) * 1000)) } else { print("F0Ac not present") }
    if samples > 1 { Thread.sleep(forTimeInterval: 1) }
}
_ = start
IOServiceClose(conn)
