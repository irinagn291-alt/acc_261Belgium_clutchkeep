import XCTest
@testable import Clutchkeep

/// Family flock_ledger: costPerUnit = Σfeed.cost / Σqty. FCR = ΣfeedKg / Σqty. healthScore = clamp(100 − mortality×140 − min(20, notes)).
final class FamilyInvariantTests: XCTestCase {
    private let calendar = RoostDates.calendar
    private let today = RoostDay.stamp(RoostDates.day(2026, 9, 11), calendar: RoostDates.calendar)

    func test_costPerUnit_isMashCostOverCreditQty() throws {
        var book = YardBook.empty
        let hen = try book.addHen(name: "Sable", dayKey: today.rawValue)
        try book.creditHen(hen, dayKey: today.rawValue)
        try book.creditHen(hen, dayKey: today.rawValue)
        try book.logMash(kilograms: 2.5, cost: 8, dayKey: today.rawValue)
        XCTAssertEqual(book.qty, 2)
        XCTAssertEqual(book.mashCost, 8, accuracy: 0.000_000_1)
        let costPerUnit = try XCTUnwrap(book.costPerUnit)
        XCTAssertEqual(costPerUnit, book.mashCost / Double(book.qty))
        XCTAssertEqual(costPerUnit, 4, accuracy: 0.000_000_1)
        XCTAssertNil(YardBook.empty.costPerUnit)
    }

    func test_fcr_isFeedKgOverCreditQty() throws {
        var book = YardBook.empty
        let hen = try book.addHen(name: "Dun", dayKey: today.rawValue)
        try book.creditHen(hen, dayKey: today.rawValue)
        try book.creditHen(hen, dayKey: today.rawValue)
        try book.creditHen(hen, dayKey: today.rawValue)
        try book.logMash(kilograms: 1.5, cost: 3, dayKey: today.rawValue)
        try book.logMash(kilograms: 1.5, cost: 3, dayKey: today.rawValue)
        XCTAssertEqual(book.feedKg, 3, accuracy: 0.000_000_1)
        let fcr = try XCTUnwrap(book.fcr)
        XCTAssertEqual(fcr, book.feedKg / Double(book.qty))
        XCTAssertEqual(fcr, 1, accuracy: 0.000_000_1)
        XCTAssertNil(YardBook.empty.fcr)
    }

    func test_healthScore_clampsMortalityAndNotes() throws {
        var book = YardBook.empty
        XCTAssertEqual(book.healthScore, 100)

        let a = try book.addHen(name: "Sable", dayKey: today.rawValue)
        let b = try book.addHen(name: "Dun", dayKey: today.rawValue)
        let c = try book.addHen(name: "Marl", dayKey: today.rawValue)
        let d = try book.addHen(name: "Wattle", dayKey: today.rawValue)
        let e = try book.addHen(name: "Kestrel", dayKey: today.rawValue)
        try book.creditHen(a, dayKey: today.rawValue)
        try book.noteDose(henID: a, note: "Grit", dayKey: today.rawValue)
        try book.noteDose(henID: b, note: "Comb", dayKey: today.rawValue)
        try book.noteDose(henID: c, note: "Dust", dayKey: today.rawValue)
        try book.cullHen(e, dayKey: today.rawValue)

        let mortality = 1.0 / 5.0
        let notes = min(20.0, Double(book.doses.count))
        let expected = min(100, max(0, 100 - mortality * 140 - notes))
        XCTAssertEqual(book.healthScore, expected, accuracy: 0.000_000_1)
        XCTAssertEqual(book.healthScore, 69, accuracy: 0.000_000_1)

        _ = d
        for index in 0 ..< 25 {
            try book.noteDose(henID: a, note: "Note \(index)", dayKey: today.rawValue)
        }
        XCTAssertEqual(book.healthScore, min(100, max(0, 100 - mortality * 140 - 20)), accuracy: 0.000_000_1)
    }

    func test_architecture_qtyIsCreditCount_cullDropsTomorrowDivisor() throws {
        var book = YardBook.empty
        let a = try book.addHen(name: "Sable", dayKey: today.rawValue)
        let b = try book.addHen(name: "Dun", dayKey: today.rawValue)
        try book.creditHen(a, dayKey: today.rawValue)
        try book.creditHen(a, dayKey: today.rawValue)
        try book.creditHen(b, dayKey: today.rawValue)
        XCTAssertEqual(book.qty, book.credits.count)
        XCTAssertEqual(book.qty, 3)
        XCTAssertEqual(try XCTUnwrap(book.eggsPerLayer(on: today.rawValue)), 1.5, accuracy: 0.000_000_1)
        XCTAssertEqual(book.divisorLayers(on: today.rawValue).count, 2)

        try book.cullHen(a, dayKey: today.rawValue)
        XCTAssertEqual(book.qty, 3)
        XCTAssertEqual(book.roost.count, 1)
        XCTAssertEqual(try XCTUnwrap(book.eggsPerLayer(on: today.rawValue)), 1.5, accuracy: 0.000_000_1)

        let tomorrow = try XCTUnwrap(today.shifting(by: 1, calendar: calendar))
        XCTAssertEqual(book.divisorLayers(on: tomorrow.rawValue).count, 1)
        XCTAssertEqual(try XCTUnwrap(book.eggsPerLayer(on: tomorrow.rawValue)), 1, accuracy: 0.000_000_1)

        let encoded = try RoostCodec.encode(book)
        let text = String(data: encoded, encoding: .utf8) ?? ""
        XCTAssertFalse(text.contains("costPerUnit"))
        XCTAssertFalse(text.contains("healthScore"))
        XCTAssertFalse(text.contains("flockSize"))
        XCTAssertFalse(text.contains("basket"))
    }
}
