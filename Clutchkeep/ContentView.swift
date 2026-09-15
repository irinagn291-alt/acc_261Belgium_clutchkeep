import SwiftUI

/// Role: Hen. Host. Walk first; then roost-tab chrome. Views never touch the store.
struct ContentView: View {
    @State private var watch: RoostWatch
    var handlesLaunch: Bool
    @Environment(\.scenePhase) private var scenePhase
    @State private var ready = false

    init(watch: RoostWatch = .live(), handlesLaunch: Bool = true) {
        self._watch = State(initialValue: watch)
        self.handlesLaunch = handlesLaunch
        self._ready = State(initialValue: !handlesLaunch)
    }

    var body: some View {
        Group {
            if handlesLaunch && !ready {
                RoostDune.background
                    .ignoresSafeArea()
                    .overlay {
                        Image(RoostPlate.splash)
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                            .accessibilityHidden(true)
                    }
                    .overlay {
                        if watch.isHauling {
                            ProgressView()
                                .tint(RoostDune.accent)
                        }
                    }
            } else if watch.onboardingComplete {
                RoostChrome(watch: watch)
            } else {
                RoostWalk(watch: watch)
            }
        }
        .tint(RoostDune.accent)
        .preferredColorScheme(.light)
        .background(RoostDune.background.ignoresSafeArea())
        .task {
            guard handlesLaunch else {
                ready = true
                watch.applyReview()
                return
            }
            await watch.appear()
            ready = true
            await Task.yield()
            watch.applyReview()
        }
        .onChange(of: watch.onboardingComplete) { _, complete in
            if complete, ready {
                watch.applyReview()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard handlesLaunch else { return }
            if phase == .inactive || phase == .background {
                Task { await watch.flush() }
            }
            if phase == .active {
                watch.markDay()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            watch.markDay()
        }
    }
}

#Preview {
    ContentView(watch: .previewPopulated(), handlesLaunch: false)
}
