import Foundation

/// Role: Hen. Simulator-only yard fill. Several named hens, mix of Pullet and Layer, credit-the-hen enabled.
enum YardSeed {
    static func book(now: Date, calendar: Calendar) -> YardBook {
        var book = YardBook.empty
        book.onboardingComplete = true
        book.hapticsOn = true
        let today = RoostDay.stamp(now, calendar: calendar)
        let yesterday = today.shifting(by: -1, calendar: calendar) ?? today
        let twoBack = today.shifting(by: -2, calendar: calendar) ?? today
        let threeBack = today.shifting(by: -3, calendar: calendar) ?? today

        let sable = seat(&book, name: "Sable", day: threeBack.rawValue)
        let dun = seat(&book, name: "Dun", day: threeBack.rawValue)
        let marl = seat(&book, name: "Marl", day: twoBack.rawValue)
        let wattle = seat(&book, name: "Wattle", day: yesterday.rawValue)
        let kestrel = seat(&book, name: "Kestrel", day: today.rawValue)

        nest(&book, sable, on: threeBack.rawValue, times: 2)
        nest(&book, sable, on: twoBack.rawValue, times: 1)
        nest(&book, sable, on: yesterday.rawValue, times: 2)
        nest(&book, sable, on: today.rawValue, times: 1)

        nest(&book, dun, on: twoBack.rawValue, times: 1)
        nest(&book, dun, on: yesterday.rawValue, times: 2)
        nest(&book, dun, on: today.rawValue, times: 1)

        nest(&book, marl, on: yesterday.rawValue, times: 1)
        nest(&book, marl, on: today.rawValue, times: 1)

        try? book.logMash(kilograms: 1.25, cost: 4.50, dayKey: threeBack.rawValue)
        try? book.logMash(kilograms: 1.40, cost: 4.80, dayKey: yesterday.rawValue)
        try? book.logMash(kilograms: 1.10, cost: 4.20, dayKey: today.rawValue)

        try? book.noteDose(henID: sable, note: "Grit dish refilled", dayKey: yesterday.rawValue)
        try? book.noteDose(henID: dun, note: "Comb looked peaked", dayKey: today.rawValue)

        _ = wattle
        _ = kestrel
        return book
    }

    private static func seat(_ book: inout YardBook, name: String, day: Int) -> UUID {
        (try? book.addHen(name: name, dayKey: day)) ?? UUID()
    }

    private static func nest(_ book: inout YardBook, _ henID: UUID, on day: Int, times: Int) {
        guard times > 0 else { return }
        for _ in 0 ..< times {
            try? book.creditHen(henID, dayKey: day)
        }
    }
}
