import SwiftUI

/// Role: Mash. Kilograms and cost on the Flock pager. costPerUnit and FCR wait on Credit qty.
struct MashBoard: View {
    var watch: RoostWatch
    var expanded: Bool
    var roomy: Bool = true
    @Binding var kilogramsDraft: String
    @Binding var costDraft: String
    @Environment(\.locale) private var locale

    private var kilograms: Double? { RoostFigures.parseKilograms(kilogramsDraft, locale: locale) }
    private var cost: Double? { RoostFigures.parseCost(costDraft, locale: locale) }
    private var canLog: Bool { kilograms != nil && cost != nil && !watch.isCommitting }

    var body: some View {
        let roll = watch.mashRoll
        VStack(alignment: .leading, spacing: RoostRail.space(2)) {
            if roomy {
                Text("Mash")
                    .roostInk(.heading)
                    .lineLimit(1)
            }
            HStack(spacing: RoostRail.space(2)) {
                figure(RoostFigures.kilograms(roll.feedKg), "Kilograms")
                figure(RoostFigures.cost(roll.mashCost), "Cost")
                figure(RoostFigures.optional(roll.costPerUnit, style: RoostFigures.perEgg), "Cost / egg")
            }
            if expanded && roomy {
                figure(RoostFigures.optional(roll.fcr, style: RoostFigures.ratio), "FCR")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if roomy {
                field("Kilograms", text: $kilogramsDraft)
                    .keyboardType(.decimalPad)
                    .accessibilityLabel("Mash kilograms")
                field("Cost", text: $costDraft)
                    .keyboardType(.decimalPad)
                    .accessibilityLabel("Mash cost")
            } else {
                HStack(spacing: RoostRail.space(1)) {
                    field("Kilograms", text: $kilogramsDraft)
                        .keyboardType(.decimalPad)
                        .accessibilityLabel("Mash kilograms")
                    field("Cost", text: $costDraft)
                        .keyboardType(.decimalPad)
                        .accessibilityLabel("Mash cost")
                }
            }
            RoostFillButton(
                title: "Log mash",
                fills: true,
                emphasized: true,
                enabled: canLog,
                busy: watch.isCommitting,
                hint: "Writes today's mash kilograms and cost"
            ) {
                RoostKeyboard.dismiss()
                guard let kilograms, let cost else { return }
                watch.logMash(kilograms: kilograms, cost: cost)
                kilogramsDraft = ""
                costDraft = ""
            }
            if expanded {
                RoostWeekFold(watch: watch, fills: true, kind: .mashKilograms)
                    .frame(maxWidth: .infinity, minHeight: roomy ? RoostRail.space(14) : 0, maxHeight: .infinity)
                    .layoutPriority(roomy ? 1 : 0)
                if roomy {
                    mashLines
                }
            }
        }
        .padding(RoostRail.space(2))
        .frame(maxWidth: .infinity, maxHeight: expanded ? .infinity : nil, alignment: .topLeading)
        .roostCard()
        .onChange(of: kilogramsDraft) { _, new in
            let cleaned = RoostFigures.sanitizeDecimal(new, locale: locale)
            if cleaned != new { kilogramsDraft = cleaned }
        }
        .onChange(of: costDraft) { _, new in
            let cleaned = RoostFigures.sanitizeDecimal(new, locale: locale)
            if cleaned != new { costDraft = cleaned }
        }
    }

    @ViewBuilder
    private var mashLines: some View {
        if watch.book.mash.isEmpty {
                Text("No mash lines yet.")
                    .font(RoostFace.font(.callout))
                    .foregroundStyle(RoostDune.ink)
        } else {
            VStack(alignment: .leading, spacing: RoostRail.space(1)) {
                    Text("Recent mash")
                        .font(RoostFace.font(.caption))
                        .foregroundStyle(RoostDune.ink)
                ForEach(Array(watch.book.mash.suffix(10).reversed())) { line in
                    HStack {
                        Text(RoostFigures.day(line.dayKey))
                            .font(RoostFace.font(.callout))
                            .foregroundStyle(RoostDune.ink)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(RoostFigures.kilograms(line.kilograms))
                            .font(RoostFace.font(.callout).monospacedDigit())
                            .foregroundStyle(RoostDune.ink)
                            .lineLimit(1)
                            .layoutPriority(1)
                        Text(RoostFigures.cost(line.cost))
                            .font(RoostFace.font(.callout).monospacedDigit())
                            .foregroundStyle(RoostDune.ink)
                            .lineLimit(1)
                            .layoutPriority(1)
                    }
                    .frame(minHeight: RoostRail.tap)
                }
            }
        }
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .font(RoostFace.font(.body).monospacedDigit())
            .foregroundStyle(RoostDune.ink)
            .padding(.horizontal, RoostRail.space(2))
            .frame(maxWidth: .infinity, minHeight: RoostRail.tap)
            .background(RoostDune.background, in: RoostRail.chipShape)
            .overlay {
                RoostRail.chipShape.stroke(RoostDune.muted.opacity(0.35), lineWidth: RoostRail.hairline)
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
