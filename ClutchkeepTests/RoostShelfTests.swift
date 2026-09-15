import XCTest
@testable import Clutchkeep

final class RoostShelfTests: XCTestCase {
    private var directory: URL!
    private var suiteName: String!
    private var defaults: UserDefaults!
    private let calendar = RoostDates.calendar

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        suiteName = "ckp.test.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        directory = nil
        defaults = nil
        suiteName = nil
    }

    func test_roundTrip_reloadPreservesCreditsMashAndLayMark() async throws {
        let shelf = makeShelf()
        let now = RoostDates.day(2026, 9, 11)
        var book = YardSeed.book(now: now, calendar: calendar)
        let sable = try XCTUnwrap(book.hens.first { $0.name == "Sable" })
        try book.creditHen(sable.id, dayKey: RoostDay.stamp(now, calendar: calendar).rawValue)
        try await shelf.save(book)

        let relaunched = makeShelf()
        let loaded = await relaunched.load()
        XCTAssertNil(loaded.warning)
        XCTAssertEqual(loaded.book.hens.count, 5)
        XCTAssertTrue(loaded.book.onboardingComplete)
        XCTAssertTrue(loaded.book.creditEnabled)
        XCTAssertEqual(loaded.book.qty, book.qty)
        XCTAssertEqual(loaded.book.layMarkCount, 3)
        XCTAssertEqual(loaded.book.mash.count, 3)
        XCTAssertEqual(loaded.book.doses.count, 2)
        XCTAssertEqual(loaded.book.hens.first { $0.name == "Sable" }?.role, .layer)
        XCTAssertEqual(loaded.book.hens.first { $0.name == "Kestrel" }?.role, .pullet)
        XCTAssertNotNil(defaults.data(forKey: YardKey.yard))
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: directory.appendingPathComponent("yard.json").path)
        )
    }

    func test_corruptPaperFallsBackToBackup() async throws {
        let shelf = makeShelf()
        let now = RoostDates.day(2026, 9, 11)
        let book = YardSeed.book(now: now, calendar: calendar)
        try await shelf.save(book)
        if let good = defaults.data(forKey: YardKey.yard) {
            defaults.set(good, forKey: YardKey.backup)
        }
        defaults.set(Data("{not-json".utf8), forKey: YardKey.yard)
        try Data("{not-json".utf8).write(to: directory.appendingPathComponent("yard.json"))

        let loaded = await makeShelf().load()
        XCTAssertEqual(loaded.warning, .recoveredFromBackup)
        XCTAssertEqual(loaded.book.hens.count, book.hens.count)
        XCTAssertEqual(loaded.book.hens.first?.name, "Sable")
    }

    func test_corruptWithoutBackupStartsEmpty() async throws {
        defaults.set(Data("nope".utf8), forKey: YardKey.yard)
        let loaded = await makeShelf().load()
        XCTAssertEqual(loaded.warning, .startedEmpty)
        XCTAssertTrue(loaded.book.hens.isEmpty)
    }

    func test_resetAllDataClearsPaper() async throws {
        let shelf = makeShelf()
        try await shelf.save(YardSeed.book(now: RoostDates.day(2026, 9, 11), calendar: calendar))
        try await shelf.resetAllData()
        let loaded = await shelf.load()
        XCTAssertTrue(loaded.book.hens.isEmpty)
        XCTAssertNil(defaults.data(forKey: YardKey.yard))
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: directory.appendingPathComponent("yard.json").path)
        )
    }

    func test_codecSwitchesOnSchemaVersion() throws {
        let data = try RoostCodec.encode(.empty)
        let decoded = try RoostCodec.decode(data)
        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertTrue(decoded.hens.isEmpty)

        XCTAssertThrowsError(try RoostCodec.decode(Data("{\"schemaVersion\":99}".utf8))) { error in
            XCTAssertEqual(error as? RoostCodec.Fault, .unsupportedSchema(99))
        }
        XCTAssertThrowsError(try RoostCodec.decode(Data("[]".utf8))) { error in
            XCTAssertEqual(error as? RoostCodec.Fault, .corrupt)
        }
    }

    func test_csvExportReadsTheSameDocument() async throws {
        let shelf = makeShelf()
        let now = RoostDates.day(2026, 9, 11)
        try await shelf.save(YardSeed.book(now: now, calendar: calendar))
        let url = try await shelf.exportCSV()
        let sheet = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(sheet.contains("kind,day,hen,role,kilograms,cost,note"))
        XCTAssertTrue(sheet.contains("credit"))
        XCTAssertTrue(sheet.contains("mash"))
        XCTAssertTrue(sheet.contains("dose"))
        XCTAssertTrue(sheet.contains("Sable"))
        XCTAssertTrue(sheet.contains("laymark"))
    }

    func test_seedFillsSeveralHensMixPulletAndLayer() {
        let now = RoostDates.day(2026, 9, 11)
        let book = YardSeed.book(now: now, calendar: calendar)
        XCTAssertEqual(book.hens.count, 5)
        XCTAssertTrue(book.onboardingComplete)
        XCTAssertTrue(book.creditEnabled)
        XCTAssertEqual(book.hens.filter { $0.role == .layer }.count, 3)
        XCTAssertEqual(book.hens.filter { $0.role == .pullet }.count, 2)
        XCTAssertGreaterThan(book.qty, 8)
        XCTAssertEqual(book.layMarkCount, 3)
        XCTAssertEqual(book.mash.count, 3)
        XCTAssertEqual(book.doses.count, 2)
        XCTAssertEqual(book.hens.map(\.name), ["Sable", "Dun", "Marl", "Wattle", "Kestrel"])
    }

    @MainActor
    func test_storeCreditMashDoseCullRoundTrip() async throws {
        let shelf = makeShelf()
        let store = RoostStore(shelf: shelf, calendar: calendar)
        let now = RoostDates.day(2026, 9, 11)
        let id = try store.addHen(name: "Sable", now: now)
        try store.creditHen(id, now: now)
        try store.creditHen(id, now: now)
        try store.logMash(kilograms: 1.2, cost: 3.5, now: now)
        try store.noteDose(henID: id, note: "Grit", now: now)
        XCTAssertEqual(store.book.qty, 2)
        XCTAssertEqual(store.book.layMarkCount, 1)
        XCTAssertEqual(store.book.hen(id: id)?.role, .layer)
        XCTAssertEqual(store.book.feedKg, 1.2, accuracy: 0.000_000_1)
        XCTAssertEqual(try XCTUnwrap(store.book.costPerUnit), 1.75, accuracy: 0.000_000_1)
        XCTAssertEqual(store.book.healthScore, min(100, max(0, 100 - 0 - 1)), accuracy: 0.000_000_1)
        try store.cullHen(id, now: now)
        XCTAssertTrue(store.book.roost.isEmpty)
        await store.flush()

        let relaunched = RoostStore(shelf: makeShelf(), calendar: calendar)
        await relaunched.load()
        XCTAssertEqual(relaunched.book.qty, 2)
        XCTAssertEqual(relaunched.book.culls.count, 1)
        XCTAssertEqual(relaunched.book.mash.count, 1)
        XCTAssertEqual(relaunched.book.healthScore, min(100, max(0, 100 - 140 - 1)), accuracy: 0.000_000_1)
    }

    @MainActor
    func test_storeEmptyPopulatedInvalidCredit() async throws {
        let store = RoostStore(shelf: makeShelf(), calendar: calendar)
        let now = RoostDates.day(2026, 9, 11)
        XCTAssertThrowsError(try store.creditHen(UUID(), now: now)) { error in
            XCTAssertEqual(error as? RoostFault, .unknownHen)
        }
        let id = try store.addHen(name: "Sable", now: now)
        try store.creditHen(id, now: now)
        XCTAssertEqual(store.book.qty, 1)
        XCTAssertThrowsError(try store.addHen(name: "", now: now)) { error in
            XCTAssertEqual(error as? RoostFault, .emptyName)
        }
    }

    #if targetEnvironment(simulator)
    @MainActor
    func test_simulatorSeedWritesOnce() async throws {
        let shelf = makeShelf()
        let store = RoostStore(shelf: shelf, calendar: calendar)
        let now = RoostDates.day(2026, 9, 11)
        await store.seedDemoIfNeeded(now: now)
        await store.seedDemoIfNeeded(now: now)
        XCTAssertEqual(store.book.hens.count, 5)
        XCTAssertTrue(store.onboardingComplete)
        XCTAssertTrue(store.book.creditEnabled)
        XCTAssertTrue(defaults.bool(forKey: YardKey.demo))
    }
    #endif

    private func makeShelf() -> RoostShelf {
        RoostShelf(directory: directory, defaultsSuiteName: suiteName, writeDelayNanoseconds: 0)
    }
}
