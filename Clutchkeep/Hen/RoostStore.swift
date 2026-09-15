import Foundation
import Observation

/// Role: Hen. One observable store owns the roost. Views call creditHen, logMash, noteDose, and cullHen.
@MainActor
@Observable
final class RoostStore {
    private(set) var book: YardBook
    private(set) var warning: RoostWarning?
    private(set) var lastWriteError: String?
    private(set) var onboardingComplete: Bool

    private let shelf: any RoostShelving
    private let calendar: Calendar

    init(shelf: any RoostShelving, calendar: Calendar = .current) {
        self.shelf = shelf
        self.calendar = calendar
        self.book = .empty
        self.onboardingComplete = false
    }

    var creditEnabled: Bool { book.creditEnabled }

    func load() async {
        let loaded = await shelf.load()
        book = loaded.book
        warning = loaded.warning
        onboardingComplete = loaded.book.onboardingComplete
        lastWriteError = nil
    }

    func addHen(name: String, now: Date = Date()) throws -> UUID {
        let day = RoostDay.stamp(now, calendar: calendar)
        let id = try book.addHen(name: name, dayKey: day.rawValue)
        persistSoon()
        return id
    }

    func creditHen(_ henID: UUID, now: Date = Date()) throws {
        let day = RoostDay.stamp(now, calendar: calendar)
        try book.creditHen(henID, dayKey: day.rawValue)
        persistSoon()
    }

    func logMash(kilograms: Double, cost: Double, now: Date = Date()) throws {
        let day = RoostDay.stamp(now, calendar: calendar)
        try book.logMash(kilograms: kilograms, cost: cost, dayKey: day.rawValue)
        persistSoon()
    }

    func noteDose(henID: UUID, note: String, now: Date = Date()) throws {
        let day = RoostDay.stamp(now, calendar: calendar)
        try book.noteDose(henID: henID, note: note, dayKey: day.rawValue)
        persistSoon()
    }

    func cullHen(_ henID: UUID, now: Date = Date()) throws {
        let day = RoostDay.stamp(now, calendar: calendar)
        try book.cullHen(henID, dayKey: day.rawValue)
        persistSoon()
    }

    func setHaptics(_ on: Bool) {
        book.hapticsOn = on
        persistSoon()
    }

    func markOnboardingComplete() {
        book.onboardingComplete = true
        onboardingComplete = true
        persistSoon()
    }

    func reopenOnboarding() {
        book.onboardingComplete = false
        onboardingComplete = false
        persistSoon()
    }

    func flush() async {
        do {
            try await shelf.save(book)
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    func resetAllData() async {
        do {
            try await shelf.resetAllData()
        } catch {
            lastWriteError = String(describing: error)
        }
        book = .empty
        onboardingComplete = false
        warning = nil
    }

    func seedDemoIfNeeded(now: Date = Date()) async {
        #if targetEnvironment(simulator)
        if await shelf.hasDemoSeed() { return }
        book = YardSeed.book(now: now, calendar: calendar)
        onboardingComplete = book.onboardingComplete
        do {
            try await shelf.save(book)
            await shelf.markDemoSeed()
        } catch {
            lastWriteError = String(describing: error)
        }
        #else
        _ = now
        #endif
    }

    func exportCSV() async throws -> URL {
        try await shelf.save(book)
        return try await shelf.exportCSV()
    }

    func install(_ book: YardBook) {
        self.book = book
        onboardingComplete = book.onboardingComplete
        warning = nil
        lastWriteError = nil
    }

    func production(now: Date = Date()) -> Production {
        book.production(on: RoostDay.stamp(now, calendar: calendar), calendar: calendar)
    }

    private func persistSoon() {
        onboardingComplete = book.onboardingComplete
        let snapshot = book
        Task { await shelf.note(snapshot) }
    }
}
