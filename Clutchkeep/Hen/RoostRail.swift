import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Role: Hen. Spacing, radii, hairline-plus-fill, and primary chrome. Cards are 14pt; chips are 10pt.
enum RoostRail {
    static let unit: CGFloat = 8
    static let tap: CGFloat = 44
    static let cardRadius: CGFloat = 14
    static let chipRadius: CGFloat = 10
    static let hairline: CGFloat = 1
    static let motion = Animation.easeInOut(duration: 0.28)
    static let fade = Animation.easeInOut(duration: 0.22)

    static func space(_ steps: Int) -> CGFloat {
        unit * CGFloat(steps)
    }

    static var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
    }

    static var chipShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: chipRadius, style: .continuous)
    }
}

/// Role: Hen. Dismisses the decimal pad. Scroll and Done also resign.
enum RoostKeyboard {
    @MainActor
    static func dismiss() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
        #endif
    }
}

/// Role: Hen. Pressed scale. Reduce Motion fades. Disabled is faded, not identical.
struct RoostPressStyle: ButtonStyle {
    var enabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        RoostPressBody(configuration: configuration, enabled: enabled)
    }
}

private struct RoostPressBody: View {
    var configuration: ButtonStyle.Configuration
    var enabled: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        configuration.label
            .scaleEffect(!reduceMotion && configuration.isPressed && enabled ? 0.97 : 1)
            .opacity(enabled ? (configuration.isPressed ? 0.88 : 1) : 0.45)
            .animation(reduceMotion ? RoostRail.fade : RoostRail.motion, value: configuration.isPressed)
    }
}

extension View {
    func roostInk(_ step: RoostFace.Step) -> some View {
        font(RoostFace.font(step))
            .foregroundStyle(RoostDune.ink)
    }

    func roostCard() -> some View {
        background(RoostDune.surface, in: RoostRail.cardShape)
            .overlay {
                RoostRail.cardShape.stroke(RoostDune.muted.opacity(0.35), lineWidth: RoostRail.hairline)
            }
    }

    func roostChipFill() -> some View {
        background(RoostDune.surface, in: RoostRail.chipShape)
            .overlay {
                RoostRail.chipShape.stroke(RoostDune.muted.opacity(0.35), lineWidth: RoostRail.hairline)
            }
    }

    func roostScreen() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(RoostDune.background.ignoresSafeArea())
    }
}

/// Role: Hen. Primary CTA: bordered prominent fill plus 1pt hairline. The fill is the target.
struct RoostFillButton: View {
    var title: String
    var detail: String? = nil
    var artwork: String? = nil
    var fills: Bool = true
    var emphasized: Bool = true
    var enabled: Bool = true
    var busy: Bool = false
    var hint: String? = nil
    var action: () -> Void

    private var active: Bool { enabled && !busy }

    var body: some View {
        Button(action: action) {
            HStack(spacing: RoostRail.space(2)) {
                if let artwork {
                    Image(artwork)
                        .resizable()
                        .scaledToFit()
                        .frame(width: RoostRail.space(3), height: RoostRail.space(3))
                        .padding(RoostRail.space(1))
                        .background(RoostDune.surface)
                        .clipShape(RoostRail.chipShape)
                        .accessibilityHidden(true)
                }
                VStack(spacing: 0) {
                    Text(title)
                        .font(RoostFace.font(.heading))
                        .foregroundStyle(emphasized && active ? RoostDune.surface : RoostDune.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    if let detail {
                        Text(detail)
                            .font(RoostFace.font(.caption))
                            .foregroundStyle(emphasized && active ? RoostDune.surface : RoostDune.ink)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                    }
                }
                .frame(maxWidth: fills ? .infinity : nil)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, RoostRail.space(2))
            .padding(.vertical, RoostRail.space(1))
            .frame(maxWidth: fills ? .infinity : nil, minHeight: RoostRail.tap)
            .background(emphasized && active ? RoostDune.accent : RoostDune.surface)
            .clipShape(RoostRail.cardShape)
            .overlay {
                RoostRail.cardShape.stroke(
                    emphasized && active ? RoostDune.accent : RoostDune.muted.opacity(0.45),
                    lineWidth: RoostRail.hairline
                )
            }
            .contentShape(RoostRail.cardShape)
        }
        .buttonStyle(RoostPressStyle(enabled: active))
        .disabled(!active)
        .accessibilityLabel(detail.map { "\(title). \($0)" } ?? title)
        .accessibilityHint(hint ?? "")
    }
}

/// Role: Hen. Recoverable fault with a retry control.
struct RoostBanner: View {
    var text: String
    var retryTitle: String = "Retry"
    var retry: () -> Void

    var body: some View {
        HStack(spacing: RoostRail.space(1)) {
            Text(text)
                .font(RoostFace.font(.callout))
                .foregroundStyle(RoostDune.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: retry) {
                Text(retryTitle)
                    .font(RoostFace.font(.callout).weight(.semibold))
                    .foregroundStyle(RoostDune.ink)
                    .frame(minWidth: RoostRail.tap, minHeight: RoostRail.tap)
                    .padding(.horizontal, RoostRail.space(1))
                    .roostChipFill()
                    .contentShape(RoostRail.chipShape)
            }
            .buttonStyle(RoostPressStyle(enabled: true))
            .accessibilityLabel(retryTitle)
        }
        .padding(.horizontal, RoostRail.space(2))
        .padding(.vertical, RoostRail.space(1))
        .frame(maxWidth: .infinity, minHeight: RoostRail.tap, alignment: .leading)
        .roostCard()
    }
}

/// Role: Hen. Sheet header with a dismiss that always works.
struct RoostSheetBar: View {
    var title: String
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: RoostRail.space(1)) {
            Text(title)
                .roostInk(.heading)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 0)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(RoostFace.font(.body).weight(.semibold))
                    .foregroundStyle(RoostDune.ink)
                    .frame(width: RoostRail.tap, height: RoostRail.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(RoostPressStyle(enabled: true))
            .accessibilityLabel("Close")
        }
        .frame(maxWidth: .infinity, minHeight: RoostRail.tap)
    }
}

/// Role: Hen. Icon control. SF Symbol is the affordance, not the brand.
struct RoostGlyphButton: View {
    var systemName: String
    var label: String
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(RoostFace.font(.body).weight(.semibold))
                .foregroundStyle(RoostDune.ink)
                .frame(width: RoostRail.tap, height: RoostRail.tap)
                .roostChipFill()
                .contentShape(RoostRail.chipShape)
        }
        .buttonStyle(RoostPressStyle(enabled: enabled))
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}

/// Role: Hen. Full-page empty or error. Art, headline, line, bottom full-width CTA.
struct NestVacancy: View {
    var image: String
    var headline: String
    var line: String
    var actionTitle: String
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        VStack(spacing: RoostRail.space(2)) {
            VStack(spacing: RoostRail.space(2)) {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: RoostRail.space(28), height: RoostRail.space(28))
                    .accessibilityHidden(true)
                Text(headline)
                    .roostInk(.heading)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                Text(line)
                    .font(RoostFace.font(.body))
                    .foregroundStyle(RoostDune.ink)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            RoostFillButton(
                title: actionTitle,
                fills: true,
                emphasized: true,
                enabled: enabled,
                action: action
            )
        }
        .padding(.horizontal, RoostRail.space(2))
        .padding(.bottom, RoostRail.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoostDune.background)
    }
}
