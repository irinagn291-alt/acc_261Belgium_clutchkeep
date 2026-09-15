import Foundation

/// Role: LayMark. Roost-tab chrome: Flock, Analytics, Settings. No Nest or Game tab.
enum RoostLane: Hashable, Sendable {
    case flock
    case analytics
    case settings
}

/// Role: LayMark. `-ReviewScreen today|log|goals` after onboarding. Does not construct a View.
enum ReviewRoost: String, Equatable, Sendable {
    case today
    case log
    case goals

    var lane: RoostLane {
        switch self {
        case .today: .flock
        case .log: .analytics
        case .goals: .settings
        }
    }
}

/// Role: LayMark. Reads ProcessInfo.processInfo.arguments once. If onboarding is still showing, the hook never fires.
struct RoostHook: Sendable, Equatable {
    private(set) var consumed: Bool

    init(consumed: Bool = false) {
        self.consumed = consumed
    }

    mutating func take(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        onboarded: Bool
    ) -> ReviewRoost? {
        guard onboarded, !consumed else { return nil }
        consumed = true
        guard let flag = arguments.firstIndex(of: "-ReviewScreen") else { return nil }
        let value = arguments.index(after: flag)
        guard arguments.indices.contains(value) else { return nil }
        return ReviewRoost(rawValue: arguments[value])
    }
}
