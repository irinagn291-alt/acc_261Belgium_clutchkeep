import SwiftUI

/// Role: Credit. Production page on Flock. Eggs per Layer and the seven-day fold, never a typed basket.
struct YieldBoard: View {
    var watch: RoostWatch
    var expanded: Bool
    var roomy: Bool = true

    var body: some View {
        let production = watch.production
        VStack(alignment: .leading, spacing: RoostRail.space(2)) {
            if roomy {
                Text("Production")
                    .roostInk(.heading)
                    .lineLimit(1)
            }
            HStack(spacing: RoostRail.space(2)) {
                figure(RoostFigures.qty(production.qty), "Credits")
                figure(
                    RoostFigures.optional(production.eggsPerLayer, style: RoostFigures.ratio),
                    "Eggs / Layer"
                )
                figure(
                    RoostFigures.optional(production.predictedQty, style: RoostFigures.ratio),
                    "7-day predict"
                )
            }
            if expanded && roomy {
                Text("Folded from credits on named hens. A Pullet is not in the Layer divisor.")
                    .font(RoostFace.font(.callout))
                    .foregroundStyle(RoostDune.ink)
                HStack(spacing: RoostRail.space(2)) {
                    figure(RoostFigures.qty(production.layMarkCount), "LayMarks")
                    figure(RoostFigures.qty(watch.roost.filter { $0.role == .layer }.count), "Layers")
                    figure(RoostFigures.qty(watch.roost.filter { $0.role == .pullet }.count), "Pullets")
                }
            }
            if expanded {
                RoostWeekFold(watch: watch, fills: true)
                    .frame(maxWidth: .infinity, minHeight: RoostRail.space(18), maxHeight: .infinity)
                    .layoutPriority(1)
            }
        }
        .padding(RoostRail.space(2))
        .frame(maxWidth: .infinity, maxHeight: expanded ? .infinity : nil, alignment: .topLeading)
        .roostCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Production. \(RoostFigures.qty(production.qty)) credits. Eggs per Layer \(RoostFigures.optional(production.eggsPerLayer, style: RoostFigures.ratio)). Seven-day predict \(RoostFigures.optional(production.predictedQty, style: RoostFigures.ratio))."
        )
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

/// Role: Credit. Seven-day credit fold. Compact counts, or bars that fill remaining height.
struct RoostWeekFold: View {
    enum Kind {
        case credits
        case mashKilograms
        case doseNotes
    }

    var watch: RoostWatch
    var fills: Bool
    var kind: Kind = .credits

    var body: some View {
        let samples = daySamples
        let peak = max(samples.map(\.value).max() ?? 1, 1)

        VStack(alignment: .leading, spacing: RoostRail.space(1)) {
            Text(heading)
                .font(RoostFace.font(.caption))
                .foregroundStyle(RoostDune.ink)
            if fills {
                GeometryReader { geo in
                    let labelBand = RoostRail.space(7)
                    let usable = max(RoostRail.space(8), geo.size.height - labelBand)
                    HStack(alignment: .bottom, spacing: RoostRail.space(1)) {
                        ForEach(samples) { sample in
                            let ratio = CGFloat(sample.value) / CGFloat(peak)
                            let barHeight = max(RoostRail.space(1), usable * ratio)
                            VStack(spacing: RoostRail.space(1)) {
                                Text(format(sample.value))
                                    .font(RoostFace.font(.callout).monospacedDigit())
                                    .foregroundStyle(RoostDune.ink)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .layoutPriority(1)
                                RoundedRectangle(cornerRadius: RoostRail.chipRadius, style: .continuous)
                                    .fill(sample.value > 0 ? RoostDune.accent : RoostDune.muted.opacity(0.45))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: RoostRail.chipRadius, style: .continuous)
                                            .stroke(RoostDune.ink.opacity(0.2), lineWidth: RoostRail.hairline)
                                    }
                                    .frame(maxWidth: RoostRail.space(5))
                                    .frame(height: barHeight)
                                Text(sample.label)
                                    .font(RoostFace.font(.caption))
                                    .foregroundStyle(RoostDune.ink)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(
                                "\(sample.label), \(format(sample.value)) \(spokenUnit)"
                            )
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(spacing: RoostRail.space(1)) {
                    ForEach(samples) { sample in
                        VStack(spacing: 0) {
                            Text(format(sample.value))
                                .font(RoostFace.font(.callout).monospacedDigit())
                                .foregroundStyle(RoostDune.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .layoutPriority(1)
                            Text(sample.label)
                                .font(RoostFace.font(.caption))
                                .foregroundStyle(RoostDune.ink)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(
                            "\(sample.label), \(format(sample.value)) \(spokenUnit)"
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: fills ? .infinity : nil, alignment: .topLeading)
    }

    private var heading: String {
        switch kind {
        case .credits: "Last seven days"
        case .mashKilograms: "Mash kilograms, last seven days"
        case .doseNotes: "Dose notes, last seven days"
        }
    }

    private var spokenUnit: String {
        switch kind {
        case .credits: "credits"
        case .mashKilograms: "kilograms"
        case .doseNotes: "notes"
        }
    }

    private func format(_ value: Double) -> String {
        switch kind {
        case .credits, .doseNotes:
            RoostFigures.qty(Int(value.rounded()))
        case .mashKilograms:
            RoostFigures.kilograms(value)
        }
    }

    private var daySamples: [WeekSample] {
        let calendar = Calendar.current
        return (0 ..< 7).map { offset in
            let day = watch.today.shifting(by: offset - 6, calendar: calendar)
            let value = day.map { amount(on: $0) } ?? 0
            return WeekSample(offset: offset, value: value, label: shortDay(offset: offset, calendar: calendar))
        }
    }

    private func amount(on day: RoostDay) -> Double {
        switch kind {
        case .credits:
            Double(watch.book.credits(on: day.rawValue).count)
        case .mashKilograms:
            watch.book.mash
                .filter { $0.dayKey == day.rawValue }
                .reduce(0) { $0 + $1.kilograms }
        case .doseNotes:
            Double(watch.book.doses.filter { $0.dayKey == day.rawValue }.count)
        }
    }

    private func shortDay(offset: Int, calendar: Calendar) -> String {
        guard let day = watch.today.shifting(by: offset - 6, calendar: calendar),
              let date = day.date(calendar: calendar)
        else { return "—" }
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.calendar = calendar
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter.string(from: date)
    }
}

private struct WeekSample: Identifiable {
    var offset: Int
    var value: Double
    var label: String
    var id: Int { offset }
}
