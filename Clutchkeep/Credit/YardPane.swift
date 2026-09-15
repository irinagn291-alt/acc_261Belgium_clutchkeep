import Foundation

/// Role: Credit. Flock pager and springboard zoom. Production, Mash, and Dose stay on Flock.
enum YardPane: Hashable, Sendable, CaseIterable {
    case production
    case mash
    case dose

    var title: String {
        switch self {
        case .production: "Production"
        case .mash: "Mash"
        case .dose: "Dose"
        }
    }
}
