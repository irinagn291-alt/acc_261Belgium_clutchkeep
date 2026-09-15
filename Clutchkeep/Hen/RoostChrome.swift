import SwiftUI

/// Role: Hen. Roost-tab chrome. Flock holds the roost; Mash and Dose fuse on the pager; Analytics and Settings are siblings.
struct RoostChrome: View {
    @Bindable var watch: RoostWatch
    @State private var lane: RoostLane
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(watch: RoostWatch) {
        self.watch = watch
        watch.applyReview()
        _lane = State(initialValue: watch.lane)
    }

    private var usesDock: Bool {
        horizontalSizeClass != .regular
    }

    var body: some View {
        Group {
            if usesDock {
                compactShell
            } else {
                systemTabs
            }
        }
        .tint(RoostDune.accent)
        .onAppear {
            watch.applyReview()
            lane = watch.lane
        }
        .onChange(of: lane) { _, new in
            watch.lane = new
        }
        .onChange(of: watch.lane) { _, new in
            lane = new
        }
    }

    private var compactShell: some View {
        lanePage
            .safeAreaInset(edge: .bottom, spacing: 0) {
                RoostDock(lane: $lane)
            }
    }

    @ViewBuilder
    private var lanePage: some View {
        switch lane {
        case .flock:
            NavigationStack {
                FlockView(watch: watch)
            }
        case .analytics:
            NavigationStack {
                AnalyticsView(watch: watch)
            }
        case .settings:
            NavigationStack {
                SettingsView(watch: watch)
            }
        }
    }

    @ViewBuilder
    private var systemTabs: some View {
        Group {
            if #available(iOS 18.0, *) {
                TabView(selection: $lane) {
                    Tab("Flock", systemImage: "square.grid.2x2", value: RoostLane.flock) {
                        NavigationStack {
                            FlockView(watch: watch)
                        }
                    }
                    Tab("Analytics", systemImage: "chart.bar", value: RoostLane.analytics) {
                        NavigationStack {
                            AnalyticsView(watch: watch)
                        }
                    }
                    Tab("Settings", systemImage: "gearshape", value: RoostLane.settings) {
                        NavigationStack {
                            SettingsView(watch: watch)
                        }
                    }
                }
                .tabViewStyle(.tabBarOnly)
            } else {
                TabView(selection: $lane) {
                    NavigationStack {
                        FlockView(watch: watch)
                    }
                    .tabItem {
                        Label("Flock", systemImage: "square.grid.2x2")
                    }
                    .tag(RoostLane.flock)

                    NavigationStack {
                        AnalyticsView(watch: watch)
                    }
                    .tabItem {
                        Label("Analytics", systemImage: "chart.bar")
                    }
                    .tag(RoostLane.analytics)

                    NavigationStack {
                        SettingsView(watch: watch)
                    }
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .tag(RoostLane.settings)
                }
            }
        }
        .toolbarBackground(RoostDune.background, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

/// Role: Hen. Full-width roost dock. Sits on the home indicator; not a floating pill.
struct RoostDock: View {
    @Binding var lane: RoostLane

    var body: some View {
        HStack(spacing: 0) {
            dockItem(.flock, title: "Flock", glyph: "square.grid.2x2", filled: "square.grid.2x2.fill")
            dockItem(.analytics, title: "Analytics", glyph: "chart.bar", filled: "chart.bar.fill")
            dockItem(.settings, title: "Settings", glyph: "gearshape", filled: "gearshape.fill")
        }
        .padding(.top, RoostRail.space(1))
        .frame(maxWidth: .infinity)
        .background {
            RoostDune.surface
                .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(RoostDune.muted.opacity(0.35))
                .frame(height: RoostRail.hairline)
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Flock, Analytics, Settings")
    }

    private func dockItem(
        _ value: RoostLane,
        title: String,
        glyph: String,
        filled: String
    ) -> some View {
        let selected = lane == value
        return Button {
            lane = value
        } label: {
            VStack(spacing: 2) {
                Image(systemName: selected ? filled : glyph)
                    .font(RoostFace.font(.body).weight(.semibold))
                Text(title)
                    .font(RoostFace.font(.caption))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(selected ? RoostDune.accent : RoostDune.ink)
            .frame(maxWidth: .infinity, minHeight: RoostRail.tap)
            .contentShape(Rectangle())
        }
        .buttonStyle(RoostPressStyle(enabled: true))
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
