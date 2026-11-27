import SwiftUI
import WooFoundation

/// Full-screen guide shown on iPhone when POS opens, until the merchant taps Start selling in person.
/// It has no close button: the merchant either enters or exits POS.
struct POSOnboardingGuideView: View {
    @Environment(\.posMetrics) private var metrics
    @State var currentPage = 0
    @State private var videoURL: URL?

    let model: POSOnboardingGuideModel
    let onExit: () -> Void

    var body: some View {
        VStack(spacing: metrics.spacing.none) {
            TabView(selection: $currentPage) {
                ForEach(steps.indices, id: \.self) { index in
                    POSOnboardingGuideStepView(step: steps[index],
                                               onLearnMore: index == steps.indices.last ? { learnMore() } : nil)
                        .scrollVerticallyIfNeeded()
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            POSPageIndicator(pageCount: steps.count,
                             currentPage: $currentPage,
                             accessibilityPageName: { steps[$0].title })
                // The top gap keeps scrolled text from running into the dots.
                .posPadding(.top, \.medium)
                .posPadding(.bottom, \.xLarge)

            POSFlowButtonsView(configuration: buttonConfiguration)
                .posStatusButtonsWidth(addsHorizontalPadding: false)
                .posBottomButtonPadding()
        }
        // The guide only shows on iPhone, so it keeps the phone scale in landscape too.
        .environment(\.posLayoutScale, .compact)
        .background(Color.posSurfaceBright.ignoresSafeArea())
        .interactiveDismissDisabled()
        .safariSheet(url: $videoURL)
        .onAppear {
            model.stepViewed(currentStep)
        }
        .onChange(of: currentPage) {
            model.stepViewed(currentStep)
        }
    }

    private var steps: [POSOnboardingGuideStep] { POSOnboardingGuideStep.all }

    private var currentStep: POSOnboardingGuideStep { steps[currentPage] }

    private func learnMore() {
        model.videoTapped(on: currentStep)
        videoURL = POSConstants.URLs.pointOfSaleOnboardingVideo.asURL()
    }

    private var buttonConfiguration: PointOfSaleFlowButtonConfiguration {
        .init(primaryButton: .init(title: Localization.startSelling,
                                   accessibilityIdentifier: "pos-onboarding-guide-start-selling-button",
                                   action: { model.startSellingTapped(on: currentStep) }),
              secondaryButton: .init(title: Localization.exit,
                                     accessibilityIdentifier: "pos-onboarding-guide-exit-button",
                                     action: {
                                         model.exitTapped(on: currentStep)
                                         onExit()
                                     }))
    }
}

private struct POSOnboardingGuideStepView: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let step: POSOnboardingGuideStep
    let onLearnMore: (() -> Void)?

    private var illustrationHeight: CGFloat {
        // Smaller in landscape, where there's little height.
        POSMetrics.onboardingGuideIllustrationHeight(isVerticallyCompact: verticalSizeClass == .compact)
    }
    @ScaledMetric private var textMinHeight: CGFloat = POSMetrics.onboardingGuideTextMinHeight

    var body: some View {
        VStack(spacing: metrics.spacing.xxLarge) {
            step.illustration.decorativeImage
                .resizable()
                .scaledToFit()
                .frame(height: illustrationHeight)

            VStack(spacing: metrics.spacing.xxLarge) {
                VStack(spacing: metrics.spacing.large) {
                    Text(step.title)
                        .font(.posHeadingBold)
                        .foregroundStyle(Color.posOnSurface)
                        .accessibilityAddTraits(.isHeader)

                    Text(step.message)
                        .font(.posBodyLargeRegular())
                        .foregroundStyle(Color.posOnSurfaceVariantHighest)
                }
                .multilineTextAlignment(.center)

                if let onLearnMore {
                    POSOnboardingGuideLearnMoreButton(action: onLearnMore)
                }
            }
            .frame(minHeight: textMinHeight, alignment: .top)
            .posPadding(.horizontal, \.xxLarge)
        }
        // Same column as the buttons, so the content is centred on their axis.
        .posStatusButtonsWidth()
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
            .font(.posBodyLargeRegular())
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
@MainActor
private func onboardingGuidePreview(page: Int) -> some View {
    POSOnboardingGuideView(currentPage: page,
                           model: POSOnboardingGuideModel(siteID: 1,
                                                          featureFlags: EmptyPOSFeatureFlags(),
                                                          preferences: POSOnboardingGuidePreferences(),
                                                          analytics: EmptyPOSAnalytics()),
                           onExit: {})
        .posPreviewSmallestPhone()
}

#Preview("Step 1") {
    onboardingGuidePreview(page: 0)
}

#Preview("Step 3, dark") {
    onboardingGuidePreview(page: 2)
        .preferredColorScheme(.dark)
}

#Preview("Accessibility text") {
    onboardingGuidePreview(page: 2)
        .dynamicTypeSize(.accessibility3)
}
#endif
