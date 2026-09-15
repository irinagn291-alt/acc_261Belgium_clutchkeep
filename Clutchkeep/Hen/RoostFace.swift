import SwiftUI

/// Role: Hen. SF Pro via Font.system. Six steps. Display is Credit qty and healthScore. Body is hen names. Caption is Pullet and Layer.
enum RoostFace {
    enum Step: CaseIterable {
        case display
        case title
        case heading
        case body
        case callout
        case caption

        var font: Font {
            switch self {
            case .display:
                .system(.largeTitle).weight(.semibold).monospacedDigit()
            case .title:
                .system(.title2).weight(.semibold)
            case .heading:
                .system(.title3).weight(.semibold)
            case .body:
                .system(.body)
            case .callout:
                .system(.callout)
            case .caption:
                .system(.caption)
            }
        }
    }

    static func font(_ step: Step) -> Font {
        step.font
    }
}
