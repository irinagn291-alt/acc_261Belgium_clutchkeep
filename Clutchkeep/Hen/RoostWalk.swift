import SwiftUI

/// Role: Hen. Three pages. Skip still writes the completion flag. Re-runnable from Settings.
struct RoostWalk: View {
    var watch: RoostWatch
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let last = 2

    var body: some View {
        VStack(spacing: RoostRail.space(2)) {
            Group {
                switch page {
                case 0:
                    pageView(
                        image: RoostPlate.onboarding1,
                        title: "The roost is the yard book",
                        line: "Named hens sit the roost. Tap a nest to log one egg. There is no flock-size field."
                    )
                case 1:
                    pageView(
                        image: RoostPlate.onboarding2,
                        title: "Tap a hen, write a credit",
                        line: "Each tap writes one Credit on that hen. Yield is the fold of those eggs."
                    )
                default:
                    pageView(
                        image: RoostPlate.onboarding3,
                        title: "Pullet, then Layer",
                        line: "The first Credit writes a LayMark and she becomes a Layer. Cull drops her from tomorrow's count."
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(reduceMotion ? nil : RoostRail.motion, value: page)
            RoostFillButton(
                title: page < last ? "Next" : "Continue",
                fills: true,
                emphasized: true,
                busy: watch.isCommitting
            ) {
                if page < last {
                    page += 1
                } else {
                    watch.finishOnboarding()
                }
            }
            Button {
                watch.finishOnboarding()
            } label: {
                Text("Skip")
                    .roostInk(.body)
                    .frame(maxWidth: .infinity, minHeight: RoostRail.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(RoostPressStyle(enabled: !watch.isCommitting))
            .disabled(watch.isCommitting)
            .accessibilityLabel("Skip")
        }
        .padding(RoostRail.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoostDune.background.ignoresSafeArea())
    }

    private func pageView(image: String, title: String, line: String) -> some View {
        VStack(spacing: RoostRail.space(2)) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityHidden(true)
            Text(title)
                .roostInk(.title)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Text(line)
                .font(RoostFace.font(.body))
                .foregroundStyle(RoostDune.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
