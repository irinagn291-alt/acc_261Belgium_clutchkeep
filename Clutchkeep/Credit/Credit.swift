import Foundation

/// Role: Credit. One egg on one hen. qty is the Credit count, never a flock-size or basket field.
struct Credit: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var henID: UUID
    var dayKey: Int
}

/// Role: Credit. Derived production fold. Never stored on the yard book.
struct Production: Equatable, Sendable {
    var qty: Int
    var layMarkCount: Int
    var eggsPerLayer: Double?
    var predictedQty: Double?
}
