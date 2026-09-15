import Foundation

/// Role: LayMark. Written once, on the first Credit that flips Pullet to Layer.
struct LayMark: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var henID: UUID
    var dayKey: Int
    var creditID: UUID
}

/// Role: LayMark. Cull drops the hen from tomorrow's Layer divisor. She leaves the roost today.
struct Cull: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var henID: UUID
    var dayKey: Int
}
