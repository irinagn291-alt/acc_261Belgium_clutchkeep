import SwiftUI

/// Role: Hen. Section 3.6 Flock tab. Named for the live driver; body is the roost yard.
struct FlockView: View {
    @Bindable var watch: RoostWatch

    var body: some View {
        RoostYard(watch: watch)
    }
}

/// Role: Hen. Flock home. The roost is the mechanic. KPI tiles zoom into Production, Mash, and Dose.
struct RoostYard: View {
    @Bindable var watch: RoostWatch
    @Namespace private var roostZoom
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isWide: Bool {
        horizontalSizeClass == .regular && !typeSize.isAccessibilitySize
    }
    @State private var kilogramsDraft = ""
    @State private var costDraft = ""
    @State private var doseHen: UUID?
    @State private var noteDraft = ""
    @State private var showSuccess = false
    @State private var successTask: Task<Void, Never>?

    var body: some View {
        Group {
            if watch.isHauling {
                ProgressView()
                    .tint(RoostDune.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel("Loading the roost")
            } else if watch.loadFailed {
                NestVacancy(
                    image: RoostPlate.emptyHome,
                    headline: "The roost could not be read.",
                    line: watch.fault ?? "The yard book started empty.",
                    actionTitle: "Retry",
                    enabled: !watch.isCommitting
                ) {
                    Task { await watch.retry() }
                }
            } else if !watch.hasFlock {
                NestVacancy(
                    image: RoostPlate.emptyHome,
                    headline: "No flock yet.",
                    line: "Add the birds first.",
                    actionTitle: "Add a hen",
                    enabled: !watch.isCommitting
                ) {
                    watch.showHenSeat = true
                }
            } else if !watch.hasCredits {
                emptyNest
            } else {
                populated
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoostDune.background.ignoresSafeArea())
        .navigationTitle("Flock")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(RoostDune.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                RoostGlyphButton(
                    systemName: "info.circle",
                    label: "Pullet then Layer"
                ) {
                    watch.showTwist = true
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                RoostGlyphButton(
                    systemName: "plus",
                    label: "Add a hen",
                    enabled: !watch.isHauling && !watch.loadFailed
                ) {
                    watch.showHenSeat = true
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { RoostKeyboard.dismiss() }
                    .frame(minHeight: RoostRail.tap)
            }
        }
        .sheet(isPresented: $watch.showHenSeat) {
            HenSeat(watch: watch, onClose: { watch.showHenSeat = false })
        }
        .sheet(isPresented: $watch.showTwist) {
            PulletFlip(watch: watch, onClose: { watch.showTwist = false })
        }
        .confirmationDialog(
            cullTitle,
            isPresented: cullPresented,
            titleVisibility: .visible
        ) {
            Button("Cull from the roost", role: .destructive) {
                if let hen = watch.cullTarget {
                    watch.cullHen(hen.id)
                }
            }
            Button("Keep her", role: .cancel) {
                watch.cullTarget = nil
            }
        }
        .sensoryFeedback(.success, trigger: watch.commitTick) { _, _ in
            watch.hapticsOn
        }
        .onChange(of: watch.creditTick) { _, _ in
            flashSuccess()
        }
        .onChange(of: watch.pane) { _, _ in
            RoostKeyboard.dismiss()
        }
        .onDisappear {
            successTask?.cancel()
        }
        .overlay {
            if showSuccess {
                Image(RoostPlate.successMark)
                    .resizable()
                    .scaledToFit()
                    .frame(width: RoostRail.space(10), height: RoostRail.space(10))
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? RoostRail.fade : RoostRail.motion, value: showSuccess)
        .animation(reduceMotion ? RoostRail.fade : RoostRail.motion, value: watch.zoom)
    }

    private var cullTitle: String {
        if let name = watch.cullTarget?.name {
            return "Cull \(name) from the roost?"
        }
        return "Cull this hen from the roost?"
    }

    private var cullPresented: Binding<Bool> {
        Binding(
            get: { watch.cullTarget != nil },
            set: { if !$0 { watch.cullTarget = nil } }
        )
    }

    private var emptyNest: some View {
        Group {
            if typeSize.isAccessibilitySize {
                ScrollView {
                    emptyStack(scrolling: true)
                }
                .scrollDismissesKeyboard(.immediately)
                .scrollIndicators(.hidden)
                .contentMargins(.bottom, RoostRail.space(3), for: .scrollContent)
            } else {
                emptyStack(scrolling: false)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
    }

    private func emptyStack(scrolling: Bool) -> some View {
        VStack(spacing: RoostRail.space(2)) {
            header
            emptyBanner
            roostAndPager(wide: isWide, scrolling: scrolling)
        }
        .padding(.horizontal, RoostRail.space(2))
        .padding(.bottom, RoostRail.space(1))
        .frame(maxWidth: .infinity, maxHeight: scrolling ? nil : .infinity, alignment: .top)
    }

    private var emptyBanner: some View {
        HStack(alignment: .top, spacing: RoostRail.space(2)) {
            Image(RoostPlate.emptyList)
                .resizable()
                .scaledToFit()
                .frame(width: RoostRail.space(8), height: RoostRail.space(8))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: RoostRail.space(1)) {
                Text("No credits yet.")
                    .roostInk(.heading)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text("Tap a hen to log an egg.")
                    .font(RoostFace.font(.body))
                    .foregroundStyle(RoostDune.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No credits yet. Tap a hen to log an egg.")
    }

    @ViewBuilder
    private var populated: some View {
        ZStack {
            if typeSize.isAccessibilitySize {
                ScrollView {
                    populatedStack(wide: isWide, scrolling: true)
                }
                .scrollDismissesKeyboard(.immediately)
                .scrollIndicators(.hidden)
                .contentMargins(.bottom, RoostRail.space(3), for: .scrollContent)
            } else {
                populatedStack(wide: isWide, scrolling: false)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            if watch.zoom != nil, let zoom = watch.zoom {
                zoomedPage(zoom)
                    .transition(reduceMotion ? .opacity : .identity)
            }
        }
    }

    private func populatedStack(wide: Bool, scrolling: Bool) -> some View {
        VStack(spacing: RoostRail.space(1)) {
            header
            if let fault = watch.fault, !watch.loadFailed {
                RoostBanner(text: fault) {
                    Task { await watch.retry() }
                }
            }
            kpiRow
            roostAndPager(wide: wide, scrolling: scrolling)
        }
        .padding(.horizontal, RoostRail.space(2))
        .padding(.bottom, RoostRail.space(1))
        .frame(maxWidth: .infinity, maxHeight: scrolling ? nil : .infinity, alignment: .top)
        .opacity(watch.zoom == nil ? 1 : 0)
    }

    @ViewBuilder
    private func roostAndPager(wide: Bool, scrolling: Bool) -> some View {
        if scrolling {
            roostGrid(wide: wide)
                .frame(maxWidth: .infinity)
                .frame(height: NestRoost.bandHeight(henCount: watch.roost.count, wide: wide))
            fusedPager(expanded: true, roomy: true)
        } else {
            GeometryReader { geo in
                let split = NestRoost.split(henCount: watch.roost.count, wide: wide, in: geo.size.height)
                VStack(spacing: RoostRail.space(1)) {
                    roostGrid(wide: wide)
                        .frame(maxWidth: .infinity)
                        .frame(height: split.roost)
                    fusedPager(expanded: true, roomy: wide)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: RoostRail.space(1)) {
            Image(RoostPlate.headerDecor)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: RoostRail.space(6))
                .accessibilityHidden(true)
            Text(watch.jobTitle)
                .roostInk(.title)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text(watch.jobLine)
                .font(RoostFace.font(.body))
                .foregroundStyle(RoostDune.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var kpiRow: some View {
        HStack(spacing: RoostRail.space(1)) {
            kpiTile(
                pane: .production,
                value: RoostFigures.qty(watch.production.qty),
                caption: "Credits"
            )
            kpiTile(
                pane: .mash,
                value: RoostFigures.optional(watch.mashRoll.costPerUnit, style: RoostFigures.perEgg),
                caption: "Cost / egg"
            )
            kpiTile(
                pane: .dose,
                value: RoostFigures.score(watch.book.healthScore),
                caption: "Health"
            )
        }
        .frame(maxWidth: .infinity)
    }

    private func kpiTile(pane: YardPane, value: String, caption: String) -> some View {
        Button {
            RoostKeyboard.dismiss()
            withAnimation(reduceMotion ? RoostRail.fade : RoostRail.motion) {
                watch.pane = pane
                watch.zoom = pane
            }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(RoostFace.font(.display))
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
            .padding(.horizontal, RoostRail.space(1))
            .padding(.vertical, RoostRail.space(1))
            .frame(maxWidth: .infinity, minHeight: RoostRail.tap, alignment: .leading)
            .roostCard()
            .contentShape(RoostRail.cardShape)
        }
        .buttonStyle(RoostPressStyle(enabled: true))
        .matchedGeometryEffect(id: pane, in: roostZoom, isSource: watch.zoom == nil)
        .accessibilityLabel("\(pane.title), \(value). Opens \(pane.title).")
    }

    private func roostGrid(wide: Bool) -> some View {
        NestRoost(
            watch: watch,
            hens: watch.roost,
            columns: NestRoost.laneCount(henCount: watch.roost.count, wide: wide)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func fusedPager(expanded: Bool, roomy: Bool) -> some View {
        VStack(spacing: RoostRail.space(1)) {
            Picker("Yard page", selection: $watch.pane) {
                ForEach(YardPane.allCases, id: \.self) { pane in
                    Text(pane.title).tag(pane)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: .infinity, minHeight: RoostRail.tap)
            .accessibilityLabel("Production, Mash, and Dose")
            paneBoard(watch.pane, expanded: expanded, roomy: roomy)
                .frame(maxWidth: .infinity, maxHeight: expanded ? .infinity : nil)
        }
        .frame(maxWidth: .infinity, maxHeight: expanded ? .infinity : nil, alignment: .top)
    }

    @ViewBuilder
    private func paneBoard(_ pane: YardPane, expanded: Bool, roomy: Bool) -> some View {
        switch pane {
        case .production:
            YieldBoard(watch: watch, expanded: expanded, roomy: roomy)
        case .mash:
            MashBoard(
                watch: watch,
                expanded: expanded,
                roomy: roomy,
                kilogramsDraft: $kilogramsDraft,
                costDraft: $costDraft
            )
        case .dose:
            DoseBoard(
                watch: watch,
                expanded: expanded,
                roomy: roomy,
                henID: $doseHen,
                noteDraft: $noteDraft
            )
        }
    }

    private func zoomedPage(_ pane: YardPane) -> some View {
        VStack(spacing: RoostRail.space(2)) {
            RoostSheetBar(title: pane.title) {
                withAnimation(reduceMotion ? RoostRail.fade : RoostRail.motion) {
                    watch.zoom = nil
                }
            }
            ScrollView {
                paneBoard(pane, expanded: true, roomy: true)
            }
            .scrollDismissesKeyboard(.immediately)
            .contentMargins(.bottom, RoostRail.space(3), for: .scrollContent)
        }
        .padding(RoostRail.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoostDune.background.ignoresSafeArea())
        .matchedGeometryEffect(id: pane, in: roostZoom, isSource: true)
        .accessibilityAddTraits(.isModal)
    }

    private func flashSuccess() {
        successTask?.cancel()
        successTask = Task {
            showSuccess = true
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard !Task.isCancelled else { return }
            showSuccess = false
        }
    }
}
