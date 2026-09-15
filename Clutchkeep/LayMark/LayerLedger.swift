import SwiftUI

/// Role: LayMark. Section 3.6 Analytics tab. Named for the live driver; body is the Layer ledger.
struct AnalyticsView: View {
    var watch: RoostWatch

    var body: some View {
        LayerLedger(watch: watch)
    }
}

/// Role: LayMark. Analytics of eggs per Layer, cost versus yield, and the seven-day fold. Not a typed basket total.
struct LayerLedger: View {
    var watch: RoostWatch
    @State private var showTwist = false
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Group {
            if watch.isHauling {
                ProgressView()
                    .tint(RoostDune.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel("Loading analytics")
            } else if watch.loadFailed {
                NestVacancy(
                    image: RoostPlate.emptyList,
                    headline: "Analytics could not be read.",
                    line: watch.fault ?? "The yard book started empty.",
                    actionTitle: "Retry",
                    enabled: !watch.isCommitting
                ) {
                    Task { await watch.retry() }
                }
            } else if !watch.hasCredits {
                NestVacancy(
                    image: RoostPlate.emptyList,
                    headline: "No credits yet.",
                    line: "Credit a hen on the roost, then read eggs per Layer here.",
                    actionTitle: "Open Flock"
                ) {
                    watch.lane = .flock
                }
            } else {
                populated
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoostDune.background.ignoresSafeArea())
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(RoostDune.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showTwist) {
            PulletFlip(watch: watch, onClose: { showTwist = false })
        }
    }

    private var populated: some View {
        GeometryReader { proxy in
            let wide = proxy.size.width >= 700 && !typeSize.isAccessibilitySize
            Group {
                if wide {
                    wideLedger
                } else {
                    stackedLedger
                }
            }
            .padding(.horizontal, RoostRail.space(2))
            .padding(.top, RoostRail.space(1))
            .padding(.bottom, RoostRail.space(2))
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
        }
    }

    private var stackedLedger: some View {
        ScrollView {
            VStack(spacing: RoostRail.space(2)) {
                faultBanner
                yieldCard(fills: false)
                costCard(fills: false)
                healthCard(fills: false)
                pulletButton
            }
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.immediately)
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }

    private var wideLedger: some View {
        VStack(spacing: RoostRail.space(2)) {
            faultBanner
            HStack(alignment: .top, spacing: RoostRail.space(2)) {
                yieldCard(fills: true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                VStack(spacing: RoostRail.space(2)) {
                    costCard(fills: true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    healthCard(fills: true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            pulletButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var faultBanner: some View {
        if let fault = watch.fault, !watch.loadFailed {
            RoostBanner(text: fault) {
                Task { await watch.retry() }
            }
        }
    }

    private func yieldCard(fills: Bool) -> some View {
        let production = watch.production
        return ledgerCard(
            title: "Yield",
            label: "Yield. \(RoostFigures.qty(production.qty)) credits. Eggs per Layer \(RoostFigures.optional(production.eggsPerLayer, style: RoostFigures.ratio)). Seven-day predict \(RoostFigures.optional(production.predictedQty, style: RoostFigures.ratio)).",
            fills: fills
        ) {
            VStack(alignment: .leading, spacing: RoostRail.space(2)) {
                HStack(spacing: RoostRail.space(2)) {
                    figure(RoostFigures.qty(production.qty), "Credits", prominent: fills)
                    figure(RoostFigures.qty(production.layMarkCount), "LayMarks", prominent: fills)
                }
                HStack(spacing: RoostRail.space(2)) {
                    figure(
                        RoostFigures.optional(production.eggsPerLayer, style: RoostFigures.ratio),
                        "Eggs / Layer",
                        prominent: fills
                    )
                    figure(
                        RoostFigures.optional(production.predictedQty, style: RoostFigures.ratio),
                        "7-day predict",
                        prominent: fills
                    )
                }
                RoostWeekFold(watch: watch, fills: fills)
                    .frame(maxWidth: .infinity, maxHeight: fills ? .infinity : nil)
            }
            .frame(maxWidth: .infinity, maxHeight: fills ? .infinity : nil, alignment: .topLeading)
        }
    }

    private func costCard(fills: Bool) -> some View {
        let roll = watch.mashRoll
        return ledgerCard(
            title: "Cost versus yield",
            label: "Cost versus yield. Mash cost \(RoostFigures.cost(roll.mashCost)). Cost per egg \(RoostFigures.optional(roll.costPerUnit, style: RoostFigures.perEgg)). FCR \(RoostFigures.optional(roll.fcr, style: RoostFigures.ratio)).",
            fills: fills
        ) {
            VStack(alignment: .leading, spacing: RoostRail.space(2)) {
                HStack(spacing: RoostRail.space(2)) {
                    figure(RoostFigures.cost(roll.mashCost), "Mash cost", prominent: fills)
                    figure(RoostFigures.kilograms(roll.feedKg), "Mash kilograms", prominent: fills)
                }
                HStack(spacing: RoostRail.space(2)) {
                    figure(
                        RoostFigures.optional(roll.costPerUnit, style: RoostFigures.perEgg),
                        "Cost per egg",
                        prominent: fills
                    )
                    figure(
                        RoostFigures.optional(roll.fcr, style: RoostFigures.ratio),
                        "FCR",
                        prominent: fills
                    )
                }
                if fills {
                    RoostWeekFold(watch: watch, fills: true, kind: .mashKilograms)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: fills ? .infinity : nil, alignment: .topLeading)
        }
    }

    private func healthCard(fills: Bool) -> some View {
        ledgerCard(
            title: "Health",
            label: "Health score \(RoostFigures.score(watch.book.healthScore)). \(RoostFigures.qty(watch.book.doses.count)) dose notes. \(RoostFigures.qty(watch.book.culls.count)) culls.",
            fills: fills
        ) {
            VStack(alignment: .leading, spacing: RoostRail.space(2)) {
                HStack(spacing: RoostRail.space(2)) {
                    figure(RoostFigures.score(watch.book.healthScore), "Health score", prominent: true)
                    figure(RoostFigures.qty(watch.book.doses.count), "Dose notes", prominent: fills)
                    figure(RoostFigures.qty(watch.book.culls.count), "Culls", prominent: fills)
                }
                if fills {
                    RoostWeekFold(watch: watch, fills: true, kind: .doseNotes)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    doseHistory
                }
            }
            .frame(maxWidth: .infinity, maxHeight: fills ? .infinity : nil, alignment: .topLeading)
        }
    }

    @ViewBuilder
    private var doseHistory: some View {
        if watch.book.doses.isEmpty {
            Text("No dose notes yet.")
                .font(RoostFace.font(.callout))
                .foregroundStyle(RoostDune.ink)
        } else {
            VStack(alignment: .leading, spacing: RoostRail.space(1)) {
                Text("Recent notes")
                    .font(RoostFace.font(.caption))
                    .foregroundStyle(RoostDune.ink)
                ForEach(Array(watch.book.doses.suffix(8).reversed())) { dose in
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

    private var pulletButton: some View {
        Button {
            showTwist = true
        } label: {
            HStack(spacing: RoostRail.space(2)) {
                Image(RoostPlate.twistHero)
                    .resizable()
                    .scaledToFit()
                    .frame(width: RoostRail.space(5), height: RoostRail.space(5))
                    .padding(RoostRail.space(1))
                    .background(RoostDune.background)
                    .clipShape(RoostRail.chipShape)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Pullet, then Layer")
                        .roostInk(.heading)
                        .lineLimit(1)
                    Text("First credit writes a LayMark. qty is credits.")
                        .font(RoostFace.font(.caption))
                        .foregroundStyle(RoostDune.ink)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .foregroundStyle(RoostDune.ink)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, RoostRail.space(2))
            .padding(.vertical, RoostRail.space(1))
            .frame(maxWidth: .infinity, minHeight: RoostRail.tap, alignment: .leading)
            .roostCard()
            .contentShape(RoostRail.cardShape)
        }
        .buttonStyle(RoostPressStyle(enabled: true))
        .accessibilityLabel("Pullet then Layer")
    }

    private func ledgerCard<Content: View>(
        title: String,
        label: String,
        fills: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: RoostRail.space(2)) {
            Text(title)
                .roostInk(.heading)
                .lineLimit(1)
            content()
                .frame(maxWidth: .infinity, maxHeight: fills ? .infinity : nil, alignment: .topLeading)
        }
        .padding(RoostRail.space(2))
        .frame(maxWidth: .infinity, maxHeight: fills ? .infinity : nil, alignment: .topLeading)
        .roostCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
    }

    private func figure(_ value: String, _ caption: String, prominent: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(RoostFace.font(prominent ? .display : .heading).monospacedDigit())
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
        .frame(maxWidth: .infinity, minHeight: RoostRail.tap, alignment: .leading)
    }
}
