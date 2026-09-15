import Foundation

/// Role: Hen. One Codable yard book. qty, costPerUnit, FCR, eggs-per-Layer, and healthScore are derived, never stored.
struct YardBook: Equatable, Sendable, Codable {
    var schemaVersion: Int
    var hens: [Hen]
    var credits: [Credit]
    var mash: [Mash]
    var doses: [Dose]
    var layMarks: [LayMark]
    var culls: [Cull]
    var onboardingComplete: Bool
    var hapticsOn: Bool

    static let empty = YardBook(
        schemaVersion: RoostCodec.schema,
        hens: [],
        credits: [],
        mash: [],
        doses: [],
        layMarks: [],
        culls: [],
        onboardingComplete: false,
        hapticsOn: true
    )

    /// Hens still seated. A cull takes her off the roost the same day.
    var roost: [Hen] {
        hens.filter { hen in !culls.contains { $0.henID == hen.id } }
    }

    /// Home verb: credit-the-hen. Enabled when at least one hen sits the roost.
    var creditEnabled: Bool {
        !roost.isEmpty
    }

    var hasHens: Bool { !hens.isEmpty }
    var hasCredits: Bool { !credits.isEmpty }

    func hen(id: UUID) -> Hen? {
        hens.first { $0.id == id }
    }

    func henIndex(id: UUID) -> Int? {
        hens.firstIndex { $0.id == id }
    }

    func cull(of henID: UUID) -> Cull? {
        culls.first { $0.henID == henID }
    }

    func isSeated(_ henID: UUID) -> Bool {
        cull(of: henID) == nil && hen(id: henID) != nil
    }

    /// Still in the Layer divisor through the cull day; gone from tomorrow.
    func isInDivisor(_ henID: UUID, on dayKey: Int) -> Bool {
        guard hen(id: henID) != nil else { return false }
        guard let cull = cull(of: henID) else { return true }
        return dayKey <= cull.dayKey
    }

    mutating func addHen(name: String, dayKey: Int, henID: UUID = UUID()) throws -> UUID {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw RoostFault.emptyName }
        hens.append(Hen(id: henID, name: trimmed, role: .pullet, seatedDay: dayKey))
        return henID
    }
}
