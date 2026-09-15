import Foundation

/// Role: Dose. A health note on a hen. healthScore folds mortality and note count.
struct Dose: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var henID: UUID
    var dayKey: Int
    var note: String
}
