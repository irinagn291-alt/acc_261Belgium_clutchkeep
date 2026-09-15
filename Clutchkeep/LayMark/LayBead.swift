import SwiftUI

/// Role: LayMark. Pullet versus Layer is a bead plus a word. Colour is never the only signal.
struct LayBead: View {
    var role: HenRole

    var body: some View {
        HStack(spacing: RoostRail.space(1)) {
            Circle()
                .stroke(RoostDune.ink, lineWidth: RoostRail.hairline)
                .background {
                    Circle().fill(role == .layer ? RoostDune.accent : RoostDune.surface)
                }
                .frame(width: RoostRail.space(2), height: RoostRail.space(2))
                .overlay {
                    if role == .layer {
                        Circle()
                            .stroke(RoostDune.ink.opacity(0.35), lineWidth: RoostRail.hairline)
                    }
                }
                .accessibilityHidden(true)
            Text(role == .layer ? "Layer" : "Pullet")
                .font(RoostFace.font(.caption))
                .foregroundStyle(RoostDune.ink)
                .lineLimit(1)
        }
        .padding(.horizontal, RoostRail.space(1))
        .frame(minHeight: RoostRail.space(3))
        .roostChipFill()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(role == .layer ? "Layer, LayMark bead" : "Pullet, no LayMark yet")
    }
}
