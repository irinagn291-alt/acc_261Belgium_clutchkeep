import XCTest
@testable import Clutchkeep

/// Primary verb creditHen: empty, populated, invalid. Twist: first Credit writes a LayMark.
final class CreditVerbTests: XCTestCase {
    private let calendar = RoostDates.calendar
    private let today = RoostDay.stamp(RoostDates.day(2026, 9, 11), calendar: RoostDates.calendar)

    func test_creditHen_emptyPopulatedInvalid() throws {
        var book = YardBook.empty
        XCTAssertFalse(book.creditEnabled)
        XCTAssertFalse(book.hasHens)
        XCTAssertFalse(book.hasCredits)
        XCTAssertThrowsError(try book.creditHen(UUID(), dayKey: today.rawValue)) { error in
            XCTAssertEqual(error as? RoostFault, .unknownHen)
        }

        let hen = try book.addHen(name: "Sable", dayKey: today.rawValue)
        XCTAssertTrue(book.creditEnabled)
        XCTAssertEqual(book.hen(id: hen)?.role, .pullet)
        try book.creditHen(hen, dayKey: today.rawValue)
        XCTAssertEqual(book.qty, 1)
        XCTAssertEqual(book.hen(id: hen)?.role, .layer)
        XCTAssertEqual(book.layMarkCount, 1)
        XCTAssertEqual(book.layMarks.first?.creditID, book.credits.first?.id)
        XCTAssertTrue(book.hasCredits)

        XCTAssertThrowsError(try book.addHen(name: "   ", dayKey: today.rawValue)) { error in
            XCTAssertEqual(error as? RoostFault, .emptyName)
        }
        XCTAssertThrowsError(try book.creditHen(UUID(), dayKey: today.rawValue)) { error in
            XCTAssertEqual(error as? RoostFault, .unknownHen)
        }
    }

    func test_firstCreditWritesLayMark_laterCreditsDoNot() throws {
        var book = YardBook.empty
        let hen = try book.addHen(name: "Dun", dayKey: today.rawValue)
        try book.creditHen(hen, dayKey: today.rawValue)
        try book.creditHen(hen, dayKey: today.rawValue)
        try book.creditHen(hen, dayKey: today.rawValue)
        XCTAssertEqual(book.qty, 3)
        XCTAssertEqual(book.layMarkCount, 1)
        XCTAssertEqual(book.hen(id: hen)?.role, .layer)
        XCTAssertEqual(book.layMarks.count, 1)
    }

    func test_cannotCreditOrDoseACulledHen() throws {
        var book = YardBook.empty
        let hen = try book.addHen(name: "Marl", dayKey: today.rawValue)
        try book.creditHen(hen, dayKey: today.rawValue)
        try book.cullHen(hen, dayKey: today.rawValue)
        XCTAssertFalse(book.creditEnabled)
        XCTAssertThrowsError(try book.creditHen(hen, dayKey: today.rawValue)) { error in
            XCTAssertEqual(error as? RoostFault, .henCulled)
        }
        XCTAssertThrowsError(try book.noteDose(henID: hen, note: "Late", dayKey: today.rawValue)) { error in
            XCTAssertEqual(error as? RoostFault, .henCulled)
        }
        XCTAssertThrowsError(try book.cullHen(hen, dayKey: today.rawValue)) { error in
            XCTAssertEqual(error as? RoostFault, .henCulled)
        }
    }

    func test_mashRejectsNegativeAndNonNumeric() throws {
        var book = YardBook.empty
        XCTAssertThrowsError(try book.logMash(kilograms: -1, cost: 1, dayKey: today.rawValue)) { error in
            XCTAssertEqual(error as? RoostFault, .invalidMash)
        }
        XCTAssertThrowsError(try book.logMash(kilograms: 1, cost: -0.5, dayKey: today.rawValue)) { error in
            XCTAssertEqual(error as? RoostFault, .invalidMash)
        }
        XCTAssertThrowsError(try book.logMash(kilograms: .nan, cost: 1, dayKey: today.rawValue)) { error in
            XCTAssertEqual(error as? RoostFault, .invalidMash)
        }
        try book.logMash(kilograms: 1.25, cost: 0, dayKey: today.rawValue)
        XCTAssertEqual(book.mash.count, 1)
    }

    func test_sevenDayPredictFoldsCredits() throws {
        var book = YardBook.empty
        let hen = try book.addHen(name: "Sable", dayKey: today.rawValue)
        try book.creditHen(hen, dayKey: today.rawValue)
        try book.creditHen(hen, dayKey: today.rawValue)
        let yesterday = try XCTUnwrap(today.shifting(by: -1, calendar: calendar))
        try book.creditHen(hen, dayKey: yesterday.rawValue)
        XCTAssertEqual(try XCTUnwrap(book.predictedQty(on: today, calendar: calendar)), 3, accuracy: 0.000_000_1)
        XCTAssertEqual(
            book.production(on: today, calendar: calendar).qty,
            3
        )
        XCTAssertNil(YardBook.empty.predictedQty(on: today, calendar: calendar))
    }

    func test_emptyDoseNoteIsInvalid() throws {
        var book = YardBook.empty
        let hen = try book.addHen(name: "Wattle", dayKey: today.rawValue)
        XCTAssertThrowsError(try book.noteDose(henID: hen, note: "  ", dayKey: today.rawValue)) { error in
            XCTAssertEqual(error as? RoostFault, .emptyNote)
        }
    }
}
