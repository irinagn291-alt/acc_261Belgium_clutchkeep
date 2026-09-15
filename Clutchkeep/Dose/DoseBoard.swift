import SwiftUI

/// Role: Dose. Health notes on a hen, fused on Flock. healthScore is a yard fold, not advice.
struct DoseBoard: View {
    var watch: RoostWatch
    var expanded: Bool
    var roomy: Bool = true
    @Binding var henID: UUID?
    @Binding var noteDraft: String

    private var canNote: Bool {
        henID != nil && !noteDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !watch.isCommitting
    }

    var body: some View {
        VStack(alignment: .leading, spacing: RoostRail.space(2)) {
            if roomy {
                Text("Dose")
                    .roostInk(.heading)
                    .lineLimit(1)
            }
            HStack(spacing: RoostRail.space(2)) {
                figure(RoostFigures.score(watch.book.healthScore), "Health score")
                figure(RoostFigures.qty(watch.book.doses.count), "Notes")
                figure(RoostFigures.qty(watch.book.culls.count), "Culls")
            }
            if watch.roost.isEmpty {
                Text("Add a hen before noting a dose.")
                    .font(RoostFace.font(.callout))
                    .foregroundStyle(RoostDune.ink)
            } else {
                Picker("Hen", selection: henBinding) {
                    ForEach(watch.roost) { hen in
                        Text(hen.name).tag(Optional(hen.id))
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, minHeight: RoostRail.tap, alignment: .leading)
                .padding(.horizontal, RoostRail.space(2))
                .roostChipFill()
                .accessibilityLabel("Hen for this dose")
                TextField("Note", text: $noteDraft, axis: .vertical)
                    .font(RoostFace.font(.body))
                    .foregroundStyle(RoostDune.ink)
                    .lineLimit(2 ... 4)
                    .padding(.horizontal, RoostRail.space(2))
                    .padding(.vertical, RoostRail.space(1))
                    .frame(maxWidth: .infinity, minHeight: RoostRail.tap, alignment: .leading)
                    .background(RoostDune.background, in: RoostRail.chipShape)
                    .overlay {
                        RoostRail.chipShape.stroke(RoostDune.muted.opacity(0.35), lineWidth: RoostRail.hairline)
                    }
                    .accessibilityLabel("Dose note")
                RoostFillButton(
                    title: "Note dose",
                    fills: true,
                    emphasized: true,
                    enabled: canNote,
                    busy: watch.isCommitting,
                    hint: "Writes a health note on the selected hen"
                ) {
                    RoostKeyboard.dismiss()
                    guard let henID else { return }
                    watch.noteDose(henID: henID, note: noteDraft)
                    noteDraft = ""
                }
            }
            if expanded {
                RoostWeekFold(watch: watch, fills: true, kind: .doseNotes)
                    .frame(maxWidth: .infinity, minHeight: roomy ? RoostRail.space(14) : 0, maxHeight: .infinity)
                    .layoutPriority(roomy ? 1 : 0)
                if roomy {
                    doseLines
                }
            }
        }
        .padding(RoostRail.space(2))
        .frame(maxWidth: .infinity, maxHeight: expanded ? .infinity : nil, alignment: .topLeading)
        .roostCard()
        .onAppear {
            if henID == nil {
                henID = watch.roost.first?.id
            }
        }
        .onChange(of: watch.roost.map(\.id)) { _, ids in
            if let henID, ids.contains(henID) { return }
            self.henID = ids.first
        }
    }

    private var henBinding: Binding<UUID?> {
        Binding(
            get: { henID ?? watch.roost.first?.id },
            set: { henID = $0 }
        )
    }

    @ViewBuilder
    private var doseLines: some View {
        if watch.book.doses.isEmpty {
            Text("No dose notes yet.")
                .font(RoostFace.font(.callout))
                .foregroundStyle(RoostDune.ink)
        } else {
            VStack(alignment: .leading, spacing: RoostRail.space(1)) {
                    Text("Recent notes")
                        .font(RoostFace.font(.caption))
                        .foregroundStyle(RoostDune.ink)
                ForEach(Array(watch.book.doses.suffix(10).reversed())) { dose in
                    HStack(alignment: .top, spacing: RoostRail.space(1)) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(watch.book.hen(id: dose.henID)?.name ?? "Hen")
                                .font(RoostFace.font(.callout).weight(.semibold))
                                .foregroundStyle(RoostDune.ink)
                                .lineLimit(1)
                            Text(dose.note)
                                .font(RoostFace.font(.callout))
                                .foregroundStyle(RoostDune.ink)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Text(RoostFigures.day(dose.dayKey))
                            .font(RoostFace.font(.caption).monospacedDigit())
                            .foregroundStyle(RoostDune.ink)
                            .lineLimit(1)
                            .layoutPriority(1)
                    }
                    .frame(minHeight: RoostRail.tap, alignment: .leading)
                }
            }
        }
    }

    private func figure(_ value: String, _ caption: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(RoostFace.font((expanded && roomy) ? .display : .heading).monospacedDigit())
                .foregroundStyle(RoostDune.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .layoutPriority(1)
            Text(caption)
                .font(RoostFace.font(.caption))
                .foregroundStyle(RoostDune.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
