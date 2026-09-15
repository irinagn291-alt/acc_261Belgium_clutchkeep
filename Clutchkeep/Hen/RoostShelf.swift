import Foundation

/// Role: Hen. Preference keys. The snapshot key is the assigned UserDefaults contract.
enum YardKey {
    static let yard = "ckp.yard.v1"
    static let backup = "ckp.yard.v1.backup"
    static let demo = "ckp.demo.v1"
}

/// Role: Hen. The only persistence seam. Views never touch UserDefaults or files.
protocol RoostShelving: Sendable {
    func load() async -> (book: YardBook, warning: RoostWarning?)
    func note(_ book: YardBook) async
    func save(_ book: YardBook) async throws
    func flush() async throws
    func resetAllData() async throws
    func hasDemoSeed() async -> Bool
    func markDemoSeed() async
    func exportCSV() async throws -> URL
}

/// Role: Hen. Memory on RoostStore is the source of truth; UserDefaults and the file are projections.
actor RoostShelf: RoostShelving {
    private let directory: URL
    private let defaultsSuiteName: String?
    private let fileManager: FileManager
    private let writeDelayNanoseconds: UInt64

    private var latest: YardBook = .empty
    private var pendingWrite = false
    private var writeTask: Task<Void, Never>?
    private(set) var lastWriteError: String?

    init(
        directory: URL,
        defaultsSuiteName: String? = nil,
        fileManager: FileManager = .default,
        writeDelayNanoseconds: UInt64 = 300_000_000
    ) {
        self.directory = directory
        self.defaultsSuiteName = defaultsSuiteName
        self.fileManager = fileManager
        self.writeDelayNanoseconds = writeDelayNanoseconds
    }

    static func applicationSupportDirectory(fileManager: FileManager = .default) throws -> URL {
        let root = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appendingPathComponent("Clutchkeep", isDirectory: true)
    }

    func load() async -> (book: YardBook, warning: RoostWarning?) {
        makeFolder()
        if let book = open(preferenceDefaults().data(forKey: YardKey.yard)) {
            latest = book
            pendingWrite = false
            return (book, nil)
        }
        if let book = openFile(paperURL) {
            latest = book
            pendingWrite = false
            return (book, nil)
        }
        if let book = open(preferenceDefaults().data(forKey: YardKey.backup)) {
            latest = book
            pendingWrite = false
            return (book, .recoveredFromBackup)
        }
        if let book = openFile(backupURL) {
            latest = book
            pendingWrite = false
            return (book, .recoveredFromBackup)
        }
        latest = .empty
        pendingWrite = false
        if hadAnyPaper() {
            return (.empty, .startedEmpty)
        }
        return (.empty, nil)
    }

    func note(_ book: YardBook) async {
        latest = book
        pendingWrite = true
        queueFlush()
    }

    func save(_ book: YardBook) async throws {
        writeTask?.cancel()
        writeTask = nil
        latest = book
        try writeNow(book)
    }

    func flush() async throws {
        writeTask?.cancel()
        writeTask = nil
        if pendingWrite {
            try writeNow(latest)
        }
    }

    func resetAllData() async throws {
        writeTask?.cancel()
        writeTask = nil
        latest = .empty
        pendingWrite = false
        lastWriteError = nil
        let defaults = preferenceDefaults()
        defaults.removeObject(forKey: YardKey.yard)
        defaults.removeObject(forKey: YardKey.backup)
        if fileManager.fileExists(atPath: paperURL.path) {
            try fileManager.removeItem(at: paperURL)
        }
        if fileManager.fileExists(atPath: backupURL.path) {
            try fileManager.removeItem(at: backupURL)
        }
        if fileManager.fileExists(atPath: sheetURL.path) {
            try fileManager.removeItem(at: sheetURL)
        }
    }

    func hasDemoSeed() async -> Bool {
        preferenceDefaults().object(forKey: YardKey.demo) != nil
    }

    func markDemoSeed() async {
        preferenceDefaults().set(true, forKey: YardKey.demo)
    }

    func exportCSV() async throws -> URL {
        try Task.checkCancellation()
        makeFolder()
        try YardSheet.writeAtomically(YardSheet.sheet(from: latest), to: sheetURL, fileManager: fileManager)
        return sheetURL
    }

    /// File IO stays on this actor, which is not MainActor — the main thread never waits on disk.
    private func writeNow(_ book: YardBook) throws {
        makeFolder()
        let data = try RoostCodec.encode(book)
        let defaults = preferenceDefaults()
        if let previous = defaults.data(forKey: YardKey.yard) {
            defaults.set(previous, forKey: YardKey.backup)
        }
        rotateFileBackup()
        try data.write(to: paperURL, options: .atomic)
        defaults.set(data, forKey: YardKey.yard)
        pendingWrite = false
        lastWriteError = nil
    }

    private func queueFlush() {
        writeTask?.cancel()
        let delay = writeDelayNanoseconds
        writeTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            await self?.flushQueued()
        }
    }

    private func flushQueued() async {
        writeTask = nil
        guard pendingWrite else { return }
        do {
            try writeNow(latest)
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    private func rotateFileBackup() {
        guard fileManager.fileExists(atPath: paperURL.path) else { return }
        if fileManager.fileExists(atPath: backupURL.path) {
            try? fileManager.removeItem(at: backupURL)
        }
        try? fileManager.copyItem(at: paperURL, to: backupURL)
    }

    private func open(_ data: Data?) -> YardBook? {
        guard let data else { return nil }
        return try? RoostCodec.decode(data)
    }

    private func openFile(_ url: URL) -> YardBook? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? RoostCodec.decode(data)
    }

    private func hadAnyPaper() -> Bool {
        preferenceDefaults().data(forKey: YardKey.yard) != nil
            || preferenceDefaults().data(forKey: YardKey.backup) != nil
            || fileManager.fileExists(atPath: paperURL.path)
            || fileManager.fileExists(atPath: backupURL.path)
    }

    private var paperURL: URL {
        directory.appendingPathComponent("yard.json")
    }

    private var backupURL: URL {
        directory.appendingPathComponent("yard.json.backup")
    }

    private var sheetURL: URL {
        directory.appendingPathComponent("yard-book.csv")
    }

    private func preferenceDefaults() -> UserDefaults {
        if let defaultsSuiteName, let suite = UserDefaults(suiteName: defaultsSuiteName) {
            return suite
        }
        return .standard
    }

    private func makeFolder() {
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }
}
