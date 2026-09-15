import Foundation

extension YardBook {
    /// Role: Dose. Note a health event on a seated hen.
    mutating func noteDose(
        henID: UUID,
        note: String,
        dayKey: Int,
        doseID: UUID = UUID()
    ) throws {
        guard hen(id: henID) != nil else { throw RoostFault.unknownHen }
        guard isSeated(henID) else { throw RoostFault.henCulled }
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw RoostFault.emptyNote }
        doses.append(Dose(id: doseID, henID: henID, dayKey: dayKey, note: trimmed))
    }

    /// Role: Dose. healthScore = clamp(100 − mortality×140 − min(20, notes)).
    var healthScore: Double {
        let seated = Double(hens.count)
        let mortality = seated > 0 ? Double(culls.count) / seated : 0
        let notes = min(20.0, Double(doses.count))
        return min(100, max(0, 100 - mortality * 140 - notes))
    }
}
