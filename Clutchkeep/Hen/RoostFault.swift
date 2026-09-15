import Foundation

/// Role: Hen. Typed faults for credit, mash, dose, and cull. Never a crash.
enum RoostFault: Error, Equatable, Sendable {
    case unknownHen
    case henCulled
    case emptyName
    case emptyNote
    case invalidMash
}

/// Role: Hen. Recoverable load outcome. Never crash on a corrupt yard book.
enum RoostWarning: Equatable, Sendable {
    case recoveredFromBackup
    case startedEmpty
}
