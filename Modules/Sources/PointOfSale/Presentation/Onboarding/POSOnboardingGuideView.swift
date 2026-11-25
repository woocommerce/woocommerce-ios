import SwiftUI
import WooFoundation

/// Full-screen guide shown on iPhone when POS opens, until the merchant taps Start selling in person.
/// It has no close button: the merchant either enters or exits POS.
struct POSOnboardingGuideView: View {
    @Environment(\.posMetrics) private var metrics
    @State private var isShowingVideo = false

    @Binding var currentStep: POSOnboardingGuideStep
    let onStartSelling: () -> Void
    let onExit: () -> Void
    let onWatchVideo: () -> Void

    var body: some View {
        VStack(spacing: metrics.spacing.none) {
            ViewThatFits(in: .vertical) {
                // Reserve every step's height, so the illustrations and titles line up between steps.
                ZStack(alignment: .top) {
                    ForEach(POSOnboardingGuideStep.allCases) { step in
                        POSOnboardingGuideStepView(step: step, onWatchVideo: {})
                    }
                }
                .hidden()
                .accessibilityHidden(true)
                .overlay {
                    pager(scrollsSteps: false)
                }
                .frame(maxHeight: .infinity)

                // When the steps don't fit (landscape, large text), each one scrolls above the dots.
                pager(scrollsSteps: true)
                    // Matches the steps' bottom padding, so clipped content doesn't run into the dots.
                    .posPadding(.bottom, \.medium)
            }
            // The design uses the regular type and spacing scale for the steps on iPhone too.
            .environment(\.posLayoutScale, .regular)

            POSPageIndicator(pageCount: POSOnboardingGuideStep.allCases.count,
                             currentPage: currentPage,
                             accessibilityPageName: { POSOnboardingGuideStep.allCases[$0].title })
                .posPadding(.bottom, \.xLarge)

            POSFlowButtonsView(configuration: buttonConfiguration)
                .posStatusButtonsWidth(addsHorizontalPadding: false)
                .posPhoneBottomButtonPadding()
        }
        // The guide only shows on iPhone. Keeping the phone scale in landscape fits the buttons' longer titles on one line.
        .environment(\.posLayoutScale, .compact)
        .background(Color.posSurfaceBright.ignoresSafeArea())
        .interactiveDismissDisabled()
        .posFullScreenCover(isPresented: $isShowingVideo) {
            SafariView(url: POSConstants.URLs.pointOfSaleSaleVideo.asURL())
        }
    }

    private func pager(scrollsSteps: Bool) -> some View {
        TabView(selection: $currentStep) {
            ForEach(POSOnboardingGuideStep.allCases) { step in
                let stepView = POSOnboardingGuideStepView(step: step, onWatchVideo: watchVideo)
                Group {
                    if scrollsSteps {
                        ScrollView {
                            stepView
                        }
                        .scrollBounceBehavior(.basedOnSize)
                        .scrollIndicatorsFlash(onAppear: true)
                        // Fading the edge hints that the step continues below.
                        .mask {
                            VStack(spacing: metrics.spacing.none) {
                                Color.black
                                LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                                    .frame(height: metrics.padding.xLarge)
                            }
                        }
                    } else {
                        stepView
                            .frame(maxHeight: .infinity, alignment: .top)
                    }
                }
                .tag(step)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private var currentPage: Binding<Int> {
        Binding(get: { currentStep.rawValue },
                set: { page in
                    // The indicator only sets pages within `pageCount`.
                    if let step = POSOnboardingGuideStep(rawValue: page) {
                        currentStep = step
                    }
                })
    }

    private func watchVideo() {
        onWatchVideo()
        isShowingVideo = true
    }

    private var buttonConfiguration: PointOfSaleFlowButtonConfiguration {
        .init(primaryButton: .init(title: Localization.startSelling,
                                   accessibilityIdentifier: "pos-onboarding-guide-start-selling-button",
                                   action: onStartSelling),
              secondaryButton: .init(title: Localization.exit,
                                     accessibilityIdentifier: "pos-onboarding-guide-exit-button",
                                     action: onExit))
    }
}

private struct POSOnboardingGuideStepView: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let step: POSOnboardingGuideStep
    let onWatchVideo: () -> Void

    private static let illustrationHeight: CGFloat = 120

    var body: some View {
        VStack(spacing: metrics.spacing.xLarge) {
            // In landscape and with accessibility text sizes, the illustration would leave little room for the text.
            if verticalSizeClass != .compact && !dynamicTypeSize.isAccessibilitySize {
                step.illustration.decorativeImage
                    .resizable()
                    .scaledToFit()
                    .frame(height: Self.illustrationHeight)
            }

            VStack(spacing: metrics.spacing.large) {
                VStack(spacing: metrics.spacing.medium) {
                    Text(step.title)
                        .font(.posBodyLargeBold)
                        .foregroundStyle(Color.posOnSurface)
                        .accessibilityAddTraits(.isHeader)

                    Text(step.message)
                        .font(.posBodyMediumRegular())
                        .foregroundStyle(Color.posOnSurfaceVariantHighest)
                }
                .multilineTextAlignment(.center)

                if step == .howASaleWorks {
                    POSOnboardingGuideLearnMoreButton(action: onWatchVideo)
                }
            }
            .posPadding(.horizontal, \.xxLarge)
        }
        .fixedSize(horizontal: false, vertical: true)
        // Same column as the buttons, so the content is centred on their axis.
        .posStatusButtonsWidth(addsHorizontalPadding: false)
        .posPadding(.vertical, \.medium)
    }
}

/// Opens a video of a sale.
private struct POSOnboardingGuideLearnMoreButton: View {
    @Environment(\.posMetrics) private var metrics

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: metrics.spacing.small) {
                Image(systemName: "play.fill")
                    .imageScale(.small)
                    .accessibilityHidden(true)
                Text(Localization.title)
            }
            .font(.posBodyMediumRegular())
            .foregroundStyle(Color.posPrimary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Localization.accessibilityLabel)
    }

    private enum Localization {
        static let title = NSLocalizedString(
            "pos.onboardingGuide.learnMore.title",
            value: "Learn more",
            comment: "Link on the last step of the POS onboarding guide that opens a video of a sale."
        )
        static let accessibilityLabel = NSLocalizedString(
            "pos.onboardingGuide.learnMore.accessibilityLabel",
            value: "Learn more: watch a video of a sale",
            comment: "Accessibility label of the Learn more link on the last step of the POS onboarding guide. It opens a video of a sale."
        )
    }
}

private extension POSOnboardingGuideView {
    enum Localization {
        static let startSelling = NSLocalizedString(
            "pos.onboardingGuide.startSellingButton",
            value: "Start selling in person",
            comment: "Primary button in the POS onboarding guide. Closes the guide and opens POS."
        )
        static let exit = NSLocalizedString(
            "pos.onboardingGuide.exitButton",
            value: "Exit POS",
            comment: "Secondary button in the POS onboarding guide. Leaves POS."
        )
    }
}

#if DEBUG
private struct POSOnboardingGuidePreview: View {
    @State var currentStep: POSOnboardingGuideStep

    var body: some View {
        POSOnboardingGuideView(currentStep: $currentStep, onStartSelling: {}, onExit: {}, onWatchVideo: {})
            .posPreviewSmallestPhone()
            .environmentObject(POSFullScreenCoverManager())
    }
}

#Preview("Step 1") {
    POSOnboardingGuidePreview(currentStep: .checkout)
}

#Preview("Step 3, dark") {
    POSOnboardingGuidePreview(currentStep: .howASaleWorks)
        .preferredColorScheme(.dark)
}

#Preview("Accessibility text") {
    POSOnboardingGuidePreview(currentStep: .howASaleWorks)
        .dynamicTypeSize(.accessibility3)
}
#endif
