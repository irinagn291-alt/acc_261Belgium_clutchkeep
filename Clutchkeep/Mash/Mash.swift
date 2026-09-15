import Foundation

/// Role: Mash. One feed line: kilograms and cost. costPerUnit and FCR fold over Credit qty.
struct Mash: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var dayKey: Int
    var kilograms: Double
    var cost: Double
}

/// Role: Mash. Derived feed fold. Never stored on the yard book.
struct MashRoll: Equatable, Sendable {
    var feedKg: Double
    var mashCost: Double
    var costPerUnit: Double?
    var fcr: Double?
}
