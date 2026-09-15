import Foundation

extension YardBook {
    /// Role: Mash. Log today's feed kilograms and cost. Rejects negative and non-numeric input.
    mutating func logMash(
        kilograms: Double,
        cost: Double,
        dayKey: Int,
        mashID: UUID = UUID()
    ) throws {
        guard kilograms.isFinite, cost.isFinite else { throw RoostFault.invalidMash }
        guard kilograms > 0, cost >= 0 else { throw RoostFault.invalidMash }
        mash.append(Mash(id: mashID, dayKey: dayKey, kilograms: kilograms, cost: cost))
    }

    /// Role: Mash. Σ mash kilograms. Never stored.
    var feedKg: Double {
        mash.reduce(0) { $0 + $1.kilograms }
    }

    var mashCost: Double {
        mash.reduce(0) { $0 + $1.cost }
    }

    /// Role: Mash. costPerUnit = Σfeed.cost / Σqty. Empty when qty is 0.
    var costPerUnit: Double? {
        guard qty > 0 else { return nil }
        return mashCost / Double(qty)
    }

    /// Role: Mash. FCR = ΣfeedKg / Σqty. Empty when qty is 0.
    var fcr: Double? {
        guard qty > 0 else { return nil }
        return feedKg / Double(qty)
    }

    var mashRoll: MashRoll {
        MashRoll(feedKg: feedKg, mashCost: mashCost, costPerUnit: costPerUnit, fcr: fcr)
    }
}
