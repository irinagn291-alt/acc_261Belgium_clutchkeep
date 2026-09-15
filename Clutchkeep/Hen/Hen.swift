import Foundation

/// Role: Hen. A named bird on the roost. Seated as Pullet; LayMark is the only way she becomes Layer.
enum HenRole: String, Codable, Sendable, Equatable {
    case pullet
    case layer
}

/// Role: Hen. One bird in the yard book. Cull keeps the row for mortality; she leaves the roost.
struct Hen: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var name: String
    var role: HenRole
    var seatedDay: Int
}
