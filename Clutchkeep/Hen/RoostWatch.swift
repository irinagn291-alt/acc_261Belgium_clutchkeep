import Foundation
import Observation

/// Role: Hen. Presentation fold over RoostStore. Views call creditHen, logMash, noteDose, and cullHen; they never touch UserDefaults.
@MainActor
@Observable
final class RoostWatch {
    let store: RoostStore
    var lane: RoostLane = .flock
    var pane: YardPane = .production
    var zoom: YardPane?
    var dayAnchor: Date
    var isHauling = false
    var isCommitting = false
    var commitTick = 0
    var creditTick = 0
    var fault: String?
    var exportURL: URL?
    var exportFailed = false
    var showHenSeat = false
    var showTwist = false
    var cullTarget: Hen?

    private var hook = RoostHook()
    private var appeared = false
    private var haulToken: UUID?
    private let calendar: Calendar
    private let now: @Sendable () -> Date
    private let shouldLoad: Bool

    init(
        store: RoostStore,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = { Date() },
        shouldLoad: Bool = true
    ) {
        self.store = store
        self.calendar = calendar
        self.now = now
        self.shouldLoad = shouldLoad
        self.dayAnchor = calendar.startOfDay(for: now())
    }

    var book: YardBook { store.book }
    var onboardingComplete: Bool { store.onboardingComplete }
    var warning: RoostWarning? { store.warning }
    var loadFailed: Bool { store.warning == .startedEmpty }
    var roost: [Hen] { store.book.roost }
    var hasFlock: Bool { !store.book.roost.isEmpty }
    var hasCredits: Bool { store.book.hasCredits }
    var creditEnabled: Bool { store.creditEnabled }
    var hapticsOn: Bool { store.book.hapticsOn }

    var today: RoostDay {
        RoostDay.stamp(dayAnchor, calendar: calendar)
    }

    var production: Production {
        store.production(now: dayAnchor)
    }

    var mashRoll: MashRoll {
        store.book.mashRoll
    }

    var jobTitle: String {
        if !hasFlock {
            return "Add a hen to the roost"
        }
        if !hasCredits {
            return "Tap a hen to log an egg"
        }
        return "Credit a hen to log an egg"
    }

    var jobLine: String {
        if !hasFlock {
            return "Name the birds first. A nest tap writes one credit."
        }
        if !hasCredits {
            return "Each tap writes one credit. The first egg marks her a Layer."
        }
        let names = roost.prefix(3).map(\.name)
        if names.isEmpty {
            return "Tap a nest on the roost. First egg marks a Layer."
        }
        return "Tap \(list(names)). First egg marks a Layer."
    }

    func appear() async {
        guard shouldLoad else {
            applyReview()
            return
        }
        if appeared {
            applyReview()
            return
        }
        appeared = true
        let token = UUID()
        haulToken = token
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard let self, self.haulToken == token else { return }
            self.isHauling = true
        }
        await store.seedDemoIfNeeded(now: now())
        await store.load()
        markDay()
        applyWriteFault()
        applyReview()
        haulToken = nil
        isHauling = false
    }

    func retry() async {
        fault = nil
        appeared = false
        await appear()
    }

    func flush() async {
        await store.flush()
        applyWriteFault()
    }

    func markDay() {
        dayAnchor = calendar.startOfDay(for: now())
    }

    func finishOnboarding() {
        store.markOnboardingComplete()
        applyReview()
    }

    func reopenOnboarding() {
        store.reopenOnboarding()
        lane = .flock
        zoom = nil
    }

    func setHaptics(_ on: Bool) {
        store.setHaptics(on)
    }

    func addHen(name: String) {
        commit {
            _ = try store.addHen(name: name, now: now())
            showHenSeat = false
        }
    }

    func creditHen(_ henID: UUID) {
        guard creditEnabled, !isCommitting else { return }
        do {
            try store.creditHen(henID, now: now())
            fault = nil
            commitTick += 1
            creditTick += 1
        } catch {
            fault = Self.copy(error)
        }
        applyWriteFault()
    }

    func logMash(kilograms: Double, cost: Double) {
        commit {
            try store.logMash(kilograms: kilograms, cost: cost, now: now())
        }
    }

    func noteDose(henID: UUID, note: String) {
        commit {
            try store.noteDose(henID: henID, note: note, now: now())
        }
    }

    func cullHen(_ henID: UUID) {
        commit {
            try store.cullHen(henID, now: now())
            cullTarget = nil
        }
    }

    func resetAll() async {
        isCommitting = true
        await store.resetAllData()
        isCommitting = false
        fault = nil
        exportURL = nil
        exportFailed = false
        lane = .flock
        pane = .production
        zoom = nil
        applyWriteFault()
    }

    func exportYard() async {
        isCommitting = true
        exportFailed = false
        do {
            exportURL = try await store.exportCSV()
            fault = nil
        } catch {
            exportFailed = true
            exportURL = nil
            fault = "The yard book could not be exported."
        }
        isCommitting = false
        applyWriteFault()
    }

    func applyReview(arguments: [String] = ProcessInfo.processInfo.arguments) {
        if let review = hook.take(arguments: arguments, onboarded: store.onboardingComplete) {
            lane = review.lane
            zoom = nil
        }
    }

    func credits(for henID: UUID) -> Int {
        store.book.credits(for: henID).count
    }

    func layMark(for henID: UUID) -> LayMark? {
        store.book.layMarks.first { $0.henID == henID }
    }

    func roleLabel(_ hen: Hen) -> String {
        hen.role == .layer ? "Layer" : "Pullet"
    }

    static func live() -> RoostWatch {
        let directory: URL
        do {
            directory = try RoostShelf.applicationSupportDirectory()
        } catch {
            directory = FileManager.default.temporaryDirectory.appendingPathComponent(
                "Clutchkeep",
                isDirectory: true
            )
        }
        return RoostWatch(store: RoostStore(shelf: RoostShelf(directory: directory)))
    }

    static func previewPopulated(now: Date = Date(), calendar: Calendar = .current) -> RoostWatch {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            "Clutchkeep-preview-\(UUID().uuidString)",
            isDirectory: true
        )
        let store = RoostStore(
            shelf: RoostShelf(directory: directory, defaultsSuiteName: "ckp.preview.\(UUID().uuidString)"),
            calendar: calendar
        )
        store.install(YardSeed.book(now: now, calendar: calendar))
        return RoostWatch(store: store, calendar: calendar, now: { now }, shouldLoad: false)
    }

    static func previewEmpty() -> RoostWatch {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            "Clutchkeep-preview-\(UUID().uuidString)",
            isDirectory: true
        )
        let store = RoostStore(
            shelf: RoostShelf(directory: directory, defaultsSuiteName: "ckp.preview.\(UUID().uuidString)")
        )
        var book = YardBook.empty
        book.onboardingComplete = true
        store.install(book)
        return RoostWatch(store: store, shouldLoad: false)
    }

    private func commit(_ work: () throws -> Void) {
        guard !isCommitting else { return }
        isCommitting = true
        defer { isCommitting = false }
        do {
            try work()
            fault = nil
            commitTick += 1
        } catch {
            fault = Self.copy(error)
        }
        applyWriteFault()
    }

    private func applyWriteFault() {
        if store.lastWriteError != nil {
            fault = "The yard book could not be written."
        }
    }

    private func list(_ names: [String]) -> String {
        switch names.count {
        case 0: "a hen"
        case 1: names[0]
        case 2: "\(names[0]) or \(names[1])"
        default: "\(names[0]), \(names[1]), or \(names[2])"
        }
    }

    private static func copy(_ error: Error) -> String {
        switch error as? RoostFault {
        case .unknownHen:
            "That hen is not on the roost."
        case .henCulled:
            "She already left the flock."
        case .emptyName:
            "Name the hen first."
        case .emptyNote:
            "Write a note first."
        case .invalidMash:
            "Kilograms must be above zero. Cost cannot be negative."
        case .none:
            "The yard book could not be updated."
        }
    }
}
