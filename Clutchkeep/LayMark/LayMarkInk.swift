import Foundation

extension YardBook {
    /// Role: LayMark. Cull takes her off the roost today and out of tomorrow's Layer divisor.
    mutating func cullHen(_ henID: UUID, dayKey: Int, cullID: UUID = UUID()) throws {
        guard hen(id: henID) != nil else { throw RoostFault.unknownHen }
        guard isSeated(henID) else { throw RoostFault.henCulled }
        culls.append(Cull(id: cullID, henID: henID, dayKey: dayKey))
    }

    func divisorLayers(on dayKey: Int) -> [Hen] {
        hens.filter { hen in
            hen.role == .layer && isInDivisor(hen.id, on: dayKey)
        }
    }
}
