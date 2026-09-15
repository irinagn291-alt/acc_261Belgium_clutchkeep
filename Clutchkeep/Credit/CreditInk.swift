import Foundation

extension YardBook {
    /// Role: Credit. A nest tap writes one Credit. First Credit writes a LayMark and flips Pullet to Layer.
    mutating func creditHen(
        _ henID: UUID,
        dayKey: Int,
        creditID: UUID = UUID(),
        markID: UUID = UUID()
    ) throws {
        guard let index = henIndex(id: henID) else { throw RoostFault.unknownHen }
        guard isSeated(henID) else { throw RoostFault.henCulled }
        credits.append(Credit(id: creditID, henID: henID, dayKey: dayKey))
        if hens[index].role == .pullet {
            hens[index].role = .layer
            layMarks.append(LayMark(id: markID, henID: henID, dayKey: dayKey, creditID: creditID))
        }
    }

    /// Role: Credit. qty is the Credit count. Never a flock-size integer.
    var qty: Int { credits.count }

    var layMarkCount: Int { layMarks.count }

    func credits(on dayKey: Int) -> [Credit] {
        credits.filter { $0.dayKey == dayKey }
    }

    func credits(for henID: UUID) -> [Credit] {
        credits.filter { $0.henID == henID }
    }

    /// Eggs per remaining Layer on that day. Pullets are not in the divisor.
    func eggsPerLayer(on dayKey: Int) -> Double? {
        let layers = hens.filter { hen in
            hen.role == .layer && isInDivisor(hen.id, on: dayKey)
        }
        guard !layers.isEmpty else { return nil }
        let ids = Set(layers.map(\.id))
        let eggs = credits.filter { ids.contains($0.henID) }.count
        return Double(eggs) / Double(layers.count)
    }

    /// Next seven days, folded from Credits in the last seven calendar days.
    func predictedQty(on day: RoostDay, calendar: Calendar) -> Double? {
        guard qty > 0 else { return nil }
        var total = 0
        for offset in 0 ..< 7 {
            guard let past = day.shifting(by: -offset, calendar: calendar) else { continue }
            total += credits(on: past.rawValue).count
        }
        guard total > 0 else { return nil }
        return Double(total)
    }

    func production(on day: RoostDay, calendar: Calendar) -> Production {
        Production(
            qty: qty,
            layMarkCount: layMarkCount,
            eggsPerLayer: eggsPerLayer(on: day.rawValue),
            predictedQty: predictedQty(on: day, calendar: calendar)
        )
    }
}
