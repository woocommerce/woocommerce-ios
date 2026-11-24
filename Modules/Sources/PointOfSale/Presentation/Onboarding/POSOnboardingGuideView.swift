import SwiftUI
import WooFoundation

/// Full-screen guide shown on iPhone when POS opens, until the merchant taps Enter POS.
/// It has no close button: the merchant either enters or exits POS.
struct POSOnboardingGuideView: View {
    @Environment(\.posMetrics) private var metrics

    @Binding var currentStep: POSOnboardingGuideStep
    let onStartSelling: () -> Void
    let onExit: () -> Void

    var body: some View {
        VStack(spacing: metrics.spacing.none) {
            TabView(selection: $currentStep) {
                ForEach(POSOnboardingGuideStep.allCases) { step in
                    POSOnboardingGuideStepView(step: step)
                        .tag(step)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            POSPageIndicator(pageCount: POSOnboardingGuideStep.allCases.count,
                             currentPage: currentPage,
                             accessibilityPageName: { POSOnboardingGuideStep.allCases[$0].title })
                .posPadding(.vertical, \.medium)

            POSFlowButtonsView(configuration: buttonConfiguration)
                .posStatusButtonsWidth()
                .posPadding(.bottom, \.medium)
        }
        .background(Color.posSurface.ignoresSafeArea())
        .interactiveDismissDisabled()
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
    @ScaledMetric private var badgeSize: CGFloat = 28

    let step: POSOnboardingGuideStep

    private static let illustrationSize: CGFloat = 140

    var body: some View {
        VStack(spacing: metrics.spacing.xLarge) {
            // In landscape and with accessibility text sizes, the illustration would leave little room for the text.
            if verticalSizeClass != .compact && !dynamicTypeSize.isAccessibilitySize {
                step.illustration.decorativeImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: Self.illustrationSize, height: Self.illustrationSize)
            }

            VStack(spacing: metrics.spacing.small) {
                Text(step.title)
                    .font(.posBodyXLargeBold)
                    .foregroundStyle(Color.posOnSurface)
                    .accessibilityAddTraits(.isHeader)

                if let message = step.message {
                    Text(message)
                        .font(.posBodyLargeRegular())
                        .foregroundStyle(Color.posOnSurfaceVariantHighest)
                } else {
                    saleSteps
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: POSStatusButtonsLayout.maxWidth)
        }
        // Top-anchored, so the illustration and title stay in place while swiping between steps.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(metrics.padding.medium)
        .posPadding(.top, \.xxLarge)
        .scrollVerticallyIfNeeded()
    }

    private var saleSteps: some View {
        VStack(alignment: .leading, spacing: metrics.spacing.small) {
            ForEach(Array(POSOnboardingGuideStep.saleSteps.enumerated()), id: \.offset) { index, label in
                HStack(spacing: metrics.spacing.medium) {
                    Text((index + 1).formatted())
                        .font(.posBodyMediumBold)
                        .foregroundStyle(Color.posOnPrimary)
                        .frame(width: badgeSize, height: badgeSize)
                        .background(Circle().fill(Color.posPrimary))
                    Text(label)
                        .font(.posBodyLargeRegular())
                        .foregroundStyle(Color.posOnSurfaceVariantHighest)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .multilineTextAlignment(.leading)
        .posPadding(.top, \.small)
    }
}

private extension POSOnboardingGuideView {
    enum Localization {
        static let startSelling = NSLocalizedString(
            "pos.onboardingGuide.enterPOSButton",
            value: "Enter POS",
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
        POSOnboardingGuideView(currentStep: $currentStep, onStartSelling: {}, onExit: {})
            .posPreviewSmallestPhone()
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
    POSOnboardingGuidePreview(currentStep: .oneStore)
        .dynamicTypeSize(.accessibility3)
}
#endif
