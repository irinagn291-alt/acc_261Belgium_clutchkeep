import SwiftUI

/// Role: Hen. Section 3.6 Settings tab. Named for the live driver; body is the yard house.
struct SettingsView: View {
    var watch: RoostWatch

    var body: some View {
        YardHouse(watch: watch)
    }
}

/// Role: Hen. Settings. CSV export, contact URL, re-run onboarding, reset. Empty, populated, and error.
struct YardHouse: View {
    var watch: RoostWatch
    @State private var confirmReset = false
    @State private var showTwist = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var typeSize

    private var isWide: Bool {
        horizontalSizeClass == .regular && !typeSize.isAccessibilitySize
    }

    var body: some View {
        Group {
            if watch.isHauling {
                ProgressView()
                    .tint(RoostDune.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel("Loading settings")
            } else if watch.loadFailed {
                NestVacancy(
                    image: RoostPlate.emptyList,
                    headline: "Settings could not be read.",
                    line: watch.fault ?? "The yard book started empty.",
                    actionTitle: "Retry",
                    enabled: !watch.isCommitting
                ) {
                    Task { await watch.retry() }
                }
            } else {
                populated
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoostDune.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(RoostDune.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showTwist) {
            PulletFlip(watch: watch, onClose: { showTwist = false })
        }
        .confirmationDialog(
            "Erase every hen, credit, mash, and dose?",
            isPresented: $confirmReset,
            titleVisibility: .visible
        ) {
            Button("Reset all data", role: .destructive) {
                Task { await watch.resetAll() }
            }
            Button("Keep the yard book", role: .cancel) {}
        }
    }

    @ViewBuilder
    private var populated: some View {
        if isWide {
            wideHouse
        } else {
            compactHouse
        }
    }

    private var compactHouse: some View {
        Form {
            emptyFlockSection
            exportFaultSection
            Section("Yard book") {
                exportControls
            }
            Section("Help") {
                helpControls
            }
            Section("This device") {
                deviceControls
            }
        }
        .scrollContentBackground(.hidden)
        .contentMargins(.bottom, RoostRail.space(3), for: .scrollContent)
        .tint(RoostDune.accent)
    }

    private var wideHouse: some View {
        VStack(spacing: RoostRail.space(2)) {
            if !watch.hasFlock {
                emptyFlockBanner
            }
            if watch.exportFailed {
                exportFaultBanner
            }
            HStack(alignment: .top, spacing: RoostRail.space(2)) {
                settingsCard("Yard book") {
                    exportControls
                    Text("CSV stays on this device. Hens, credits, mash, and doses.")
                        .font(RoostFace.font(.callout))
                        .foregroundStyle(RoostDune.ink)
                    yardSnapshot
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                VStack(spacing: RoostRail.space(2)) {
                    settingsCard("Help") {
                        helpControls
                        Text("Contact opens the support page. First credit on a Pullet writes a LayMark and marks her a Layer.")
                            .font(RoostFace.font(.callout))
                            .foregroundStyle(RoostDune.ink)
                    }
                    settingsCard("This device") {
                        deviceControls
                        Text("Reset clears every hen, credit, mash, and dose.")
                            .font(RoostFace.font(.callout))
                            .foregroundStyle(RoostDune.ink)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, RoostRail.space(2))
        .padding(.top, RoostRail.space(1))
        .padding(.bottom, RoostRail.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .buttonStyle(.plain)
        .tint(RoostDune.accent)
    }

    @ViewBuilder
    private var emptyFlockSection: some View {
        if !watch.hasFlock {
            Section {
                emptyFlockBanner
                    .padding(.vertical, RoostRail.space(1))
                    .listRowBackground(RoostDune.surface)
            }
        }
    }

    @ViewBuilder
    private var exportFaultSection: some View {
        if watch.exportFailed {
            Section {
                exportFaultBanner
                    .padding(.vertical, RoostRail.space(1))
                    .listRowBackground(RoostDune.surface)
            }
        }
    }

    private var emptyFlockBanner: some View {
        VStack(alignment: .leading, spacing: RoostRail.space(1)) {
            Image(RoostPlate.emptyList)
                .resizable()
                .scaledToFit()
                .frame(width: RoostRail.space(14), height: RoostRail.space(14))
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
            Text("No flock yet.")
                .roostInk(.heading)
            Text("Add a hen on the roost. Contact, export, and reset stay here.")
                .font(RoostFace.font(.body))
                .foregroundStyle(RoostDune.ink)
            RoostFillButton(
                title: "Add a hen",
                fills: true,
                emphasized: true
            ) {
                watch.lane = .flock
                watch.showHenSeat = true
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var exportFaultBanner: some View {
        VStack(alignment: .leading, spacing: RoostRail.space(1)) {
            Text("Export did not finish")
                .roostInk(.heading)
            Text("The CSV stays on this device. Retry the write.")
                .font(RoostFace.font(.callout))
                .foregroundStyle(RoostDune.ink)
            RoostFillButton(
                title: "Retry export",
                fills: true,
                emphasized: true,
                enabled: !watch.isCommitting,
                busy: watch.isCommitting
            ) {
                Task { await watch.exportYard() }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var exportControls: some View {
        Button {
            Task { await watch.exportYard() }
        } label: {
            settingsLabel("Export CSV", symbol: "square.and.arrow.up")
        }
        .buttonStyle(RoostPressStyle(enabled: !watch.isCommitting))
        .disabled(watch.isCommitting)
        .listRowBackground(RoostDune.surface)
        if let url = watch.exportURL {
            ShareLink(item: url) {
                settingsLabel("Share the yard sheet", symbol: "square.and.arrow.up.on.square")
            }
            .buttonStyle(RoostPressStyle(enabled: true))
            .listRowBackground(RoostDune.surface)
        }
    }

    @ViewBuilder
    private var helpControls: some View {
        Link(destination: RoostLink.contact) {
            settingsLabel("Contact Clutchkeep", symbol: "envelope")
        }
        .buttonStyle(RoostPressStyle(enabled: true))
        .listRowBackground(RoostDune.surface)
        .accessibilityHint("Opens the contact page")
        Button {
            showTwist = true
        } label: {
            settingsLabel("Pullet then Layer", symbol: "info.circle")
        }
        .buttonStyle(RoostPressStyle(enabled: true))
        .listRowBackground(RoostDune.surface)
    }

    @ViewBuilder
    private var deviceControls: some View {
        Toggle(isOn: hapticsBinding) {
            settingsLabel("Haptics", symbol: "waveform")
        }
        .listRowBackground(RoostDune.surface)
        Button {
            watch.reopenOnboarding()
        } label: {
            settingsLabel("Re-run onboarding", symbol: "arrow.counterclockwise")
        }
        .buttonStyle(RoostPressStyle(enabled: true))
        .listRowBackground(RoostDune.surface)
        Button(role: .destructive) {
            confirmReset = true
        } label: {
            settingsLabel("Reset all data", symbol: "trash")
        }
        .buttonStyle(RoostPressStyle(enabled: !watch.isCommitting))
        .disabled(watch.isCommitting)
        .listRowBackground(RoostDune.surface)
    }

    private var yardSnapshot: some View {
        let production = watch.production
        return VStack(alignment: .leading, spacing: RoostRail.space(2)) {
            Text("Current yard")
                .font(RoostFace.font(.caption))
                .foregroundStyle(RoostDune.ink)
            HStack(spacing: RoostRail.space(2)) {
                snapshotFigure(RoostFigures.qty(production.qty), "Credits")
                snapshotFigure(RoostFigures.qty(watch.roost.count), "Hens")
                snapshotFigure(RoostFigures.score(watch.book.healthScore), "Health")
            }
            HStack(spacing: RoostRail.space(2)) {
                snapshotFigure(RoostFigures.kilograms(watch.mashRoll.feedKg), "Mash kg")
                snapshotFigure(RoostFigures.qty(watch.book.doses.count), "Dose notes")
                snapshotFigure(
                    RoostFigures.optional(production.eggsPerLayer, style: RoostFigures.ratio),
                    "Eggs / Layer"
                )
            }
            RoostWeekFold(watch: watch, fills: true)
                .frame(maxWidth: .infinity, minHeight: RoostRail.space(16), maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Yard snapshot. \(RoostFigures.qty(production.qty)) credits. \(RoostFigures.qty(watch.roost.count)) hens."
        )
    }

    private func snapshotFigure(_ value: String, _ caption: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(RoostFace.font(.heading).monospacedDigit())
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

    private func settingsCard<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: RoostRail.space(1)) {
            Text(title)
                .font(RoostFace.font(.caption))
                .foregroundStyle(RoostDune.ink)
                .padding(.horizontal, RoostRail.space(1))
            VStack(alignment: .leading, spacing: RoostRail.space(1)) {
                content()
            }
            .padding(.horizontal, RoostRail.space(2))
            .padding(.vertical, RoostRail.space(2))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .roostCard()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var hapticsBinding: Binding<Bool> {
        Binding(
            get: { watch.hapticsOn },
            set: { watch.setHaptics($0) }
        )
    }

    private func settingsLabel(_ title: String, symbol: String) -> some View {
        Label {
            Text(title)
                .font(RoostFace.font(.body))
                .foregroundStyle(RoostDune.ink)
                .lineLimit(1)
        } icon: {
            Image(systemName: symbol)
                .foregroundStyle(RoostDune.ink)
        }
        .frame(maxWidth: .infinity, minHeight: RoostRail.tap, alignment: .leading)
        .contentShape(Rectangle())
    }
}
