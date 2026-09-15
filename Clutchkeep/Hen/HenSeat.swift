import SwiftUI

/// Role: Hen. Seat a named Pullet on the roost. The first Credit later writes her LayMark.
struct HenSeat: View {
    var watch: RoostWatch
    var onClose: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    private var trimmed: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: RoostRail.space(2)) {
                    RoostSheetBar(title: "Add a hen") {
                        close()
                    }
                    Text("She sits the roost as a Pullet until her first credit.")
                        .font(RoostFace.font(.body))
                        .foregroundStyle(RoostDune.ink)
                    TextField("Hen name", text: $name)
                        .font(RoostFace.font(.body))
                        .foregroundStyle(RoostDune.ink)
                        .textInputAutocapitalization(.words)
                        .padding(.horizontal, RoostRail.space(2))
                        .frame(maxWidth: .infinity, minHeight: RoostRail.tap)
                        .background(RoostDune.background, in: RoostRail.chipShape)
                        .overlay {
                            RoostRail.chipShape.stroke(RoostDune.muted.opacity(0.35), lineWidth: RoostRail.hairline)
                        }
                        .accessibilityLabel("Hen name")
                }
                .padding(RoostRail.space(2))
            }
            .scrollDismissesKeyboard(.immediately)
            .scrollContentBackground(.hidden)
            .safeAreaInset(edge: .bottom) {
                RoostFillButton(
                    title: "Add a hen",
                    fills: true,
                    emphasized: true,
                    enabled: !trimmed.isEmpty && !watch.isCommitting,
                    busy: watch.isCommitting
                ) {
                    RoostKeyboard.dismiss()
                    watch.addHen(name: trimmed)
                    close()
                }
                .padding(.horizontal, RoostRail.space(2))
                .padding(.bottom, RoostRail.space(2))
                .background(RoostDune.background)
            }
            .roostScreen()
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { RoostKeyboard.dismiss() }
                        .frame(minHeight: RoostRail.tap)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func close() {
        onClose()
        dismiss()
    }
}
