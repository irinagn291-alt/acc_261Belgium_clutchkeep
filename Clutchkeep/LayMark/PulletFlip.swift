import SwiftUI

/// Role: LayMark. Own screen for pullet-then-layer, plus the bead surface on the roost.
struct PulletFlip: View {
    var watch: RoostWatch
    var onClose: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: RoostRail.space(2)) {
                    Image(RoostPlate.twistHero)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: RoostRail.space(28))
                        .background(RoostDune.surface)
                        .clipShape(RoostRail.cardShape)
                        .overlay {
                            RoostRail.cardShape.stroke(RoostDune.muted.opacity(0.35), lineWidth: RoostRail.hairline)
                        }
                        .accessibilityHidden(true)
                    Text("Pullet, then Layer")
                        .roostInk(.title)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Text("A tap writes one Credit on that hen. The first Credit writes a LayMark and flips Pullet to Layer. Later credits never write another LayMark.")
                        .font(RoostFace.font(.body))
                        .foregroundStyle(RoostDune.ink)
                    Text("qty is the Credit count. Cull removes her from tomorrow's Layer divisor. There is no flock-size field and no basket field.")
                        .font(RoostFace.font(.body))
                        .foregroundStyle(RoostDune.ink)
                    if watch.roost.isEmpty {
                        Text("Add a hen on the roost, then tap her nest.")
                            .font(RoostFace.font(.callout))
                            .foregroundStyle(RoostDune.ink)
                    } else {
                        ForEach(watch.roost) { hen in
                            henRow(hen)
                        }
                    }
                    RoostFillButton(
                        title: watch.hasFlock ? "Back to the roost" : "Add a hen",
                        fills: true,
                        emphasized: true
                    ) {
                        if watch.hasFlock {
                            close()
                        } else {
                            watch.showHenSeat = true
                            close()
                        }
                    }
                }
                .padding(RoostRail.space(2))
            }
            .scrollContentBackground(.hidden)
            .contentMargins(.bottom, RoostRail.space(3), for: .scrollContent)
            .background(RoostDune.background.ignoresSafeArea())
            .navigationTitle("Pullet then Layer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RoostDune.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    RoostGlyphButton(systemName: "xmark", label: "Close") {
                        close()
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .animation(reduceMotion ? RoostRail.fade : RoostRail.motion, value: watch.book.layMarkCount)
    }

    private func henRow(_ hen: Hen) -> some View {
        let count = watch.credits(for: hen.id)
        let canCredit = watch.creditEnabled && !watch.isCommitting
        return Button {
            watch.creditHen(hen.id)
        } label: {
            HStack(spacing: RoostRail.space(2)) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(hen.name)
                        .roostInk(.heading)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("\(RoostFigures.qty(count)) credits")
                        .font(RoostFace.font(.callout).monospacedDigit())
                        .foregroundStyle(RoostDune.ink)
                        .lineLimit(1)
                        .layoutPriority(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                LayBead(role: hen.role)
            }
            .padding(RoostRail.space(2))
            .frame(maxWidth: .infinity, minHeight: RoostRail.tap, alignment: .leading)
            .roostCard()
            .contentShape(RoostRail.cardShape)
        }
        .buttonStyle(RoostPressStyle(enabled: canCredit))
        .disabled(!canCredit)
        .accessibilityLabel("\(hen.name), \(watch.roleLabel(hen)), \(RoostFigures.qty(count)) credits. Logs one egg.")
        .accessibilityHint("Writes one credit on this hen")
    }

    private func close() {
        onClose?()
        dismiss()
    }
}
