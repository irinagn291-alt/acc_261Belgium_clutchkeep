import Foundation

/// Role: Hen. Calendar day as Int YYYYMMDD from startOfDay — never a Date dictionary key.
struct RoostDay: RawRepresentable, Hashable, Sendable, Codable, Comparable {
    let rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static func stamp(_ date: Date, calendar: Calendar) -> RoostDay {
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let year = parts.year ?? 1970
        let month = parts.month ?? 1
        let day = parts.day ?? 1
        return RoostDay(rawValue: year * 10_000 + month * 100 + day)
    }

    func date(calendar: Calendar) -> Date? {
        var parts = DateComponents()
        parts.year = rawValue / 10_000
        parts.month = (rawValue / 100) % 100
        parts.day = rawValue % 100
        guard let built = calendar.date(from: parts) else { return nil }
        return calendar.startOfDay(for: built)
    }

    func shifting(by days: Int, calendar: Calendar) -> RoostDay? {
        guard let start = date(calendar: calendar) else { return nil }
        guard let moved = calendar.date(byAdding: .day, value: days, to: start) else { return nil }
        return RoostDay.stamp(moved, calendar: calendar)
    }

    static func < (lhs: RoostDay, rhs: RoostDay) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
