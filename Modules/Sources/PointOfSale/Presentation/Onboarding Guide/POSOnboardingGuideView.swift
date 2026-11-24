import SwiftUI
import WooFoundation

/// Full-screen guide shown on iPhone when POS opens, until the merchant taps Start selling.
/// It has no close button: the merchant either starts selling or exits POS.
struct POSOnboardingGuideView: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric private var contentMaxWidth = POSStatusButtonsLayout.maxWidth

    @Binding var currentStep: POSOnboardingGuideStep
    let onStartSelling: () -> Void
    let onExit: () -> Void

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: metrics.spacing.none) {
                TabView(selection: $currentStep) {
                    ForEach(POSOnboardingGuideStep.allCases) { step in
                        page(for: step)
                            .frame(maxWidth: contentMaxWidth)
                            .frame(maxWidth: .infinity)
                            .posContentPadding(.horizontal, metrics.padding.medium)
                            .scrollVerticallyIfNeeded()
                            .tag(step)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .accessibilityIdentifier("pos-onboarding-guide")

                POSOnboardingGuidePageIndicator(currentPage: currentPage,
                                                totalPages: POSOnboardingGuideStep.allCases.count)
                    .posPadding(.top, \.medium)
                    .accessibilityIdentifier("pos-onboarding-guide-page-indicator")

                POSFlowButtonsView(configuration: buttonConfiguration)
                    // Side by side in landscape, so the buttons leave room for the step.
                    .environment(\.horizontalSizeClass, verticalSizeClass == .compact ? .regular : horizontalSizeClass)
                    .posStatusButtonsWidth(addsHorizontalPadding: false)
                    .posPhoneBottomButtonPadding(bottom: POSCompactFooterLayout.bottomPadding(safeAreaInset: geometry.safeAreaInsets.bottom,
                                                                                             metrics: metrics))
            }
        }
        .background(Color.posSurface.ignoresSafeArea())
    }

    /// The hero gives its space to the text in landscape and with accessibility text sizes.
    private var showsHero: Bool {
        verticalSizeClass != .compact && !dynamicTypeSize.isAccessibilitySize
    }

    private func page(for step: POSOnboardingGuideStep) -> some View {
        ZStack(alignment: .top) {
            if showsHero {
                // Every page takes the height of the tallest step, so the hero stays in place while swiping.
                ForEach(POSOnboardingGuideStep.allCases) {
                    POSOnboardingGuideStepView(step: $0, showsHero: true)
                        .hidden()
                }
            }
            POSOnboardingGuideStepView(step: step, showsHero: showsHero)
        }
    }

    private var currentPage: Binding<Int> {
        Binding(get: { currentStep.rawValue },
                set: { currentStep = POSOnboardingGuideStep(rawValue: $0) ?? currentStep })
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

    let step: POSOnboardingGuideStep
    let showsHero: Bool

    private static let heroSize: CGFloat = 96

    var body: some View {
        VStack(spacing: metrics.spacing.large) {
            if showsHero {
                Image(systemName: step.heroSystemImage)
                    .font(.system(size: Self.heroSize, weight: .regular))
                    .foregroundStyle(Color.posPrimary)
                    .accessibilityHidden(true)
            }

            VStack(spacing: metrics.spacing.medium) {
                Text(step.title)
                    .font(.posHeadingBold)
                    .foregroundStyle(Color.posOnSurface)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                if let message = step.message {
                    Text(message)
                        .font(.posBodyLargeRegular())
                        .foregroundStyle(Color.posOnSurfaceVariantHighest)
                        .multilineTextAlignment(.center)
                }

                if !step.saleSteps.isEmpty {
                    saleStepsList
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .posPadding(.vertical, \.medium)
    }

    private var saleStepsList: some View {
        VStack(alignment: .leading, spacing: metrics.spacing.medium) {
            ForEach(Array(step.saleSteps.enumerated()), id: \.offset) { index, text in
                POSOnboardingGuideSaleStepRow(number: index + 1, text: text)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct POSOnboardingGuideSaleStepRow: View {
    @Environment(\.posMetrics) private var metrics
    @ScaledMetric(relativeTo: .body) private var badgeSize: CGFloat = 32

    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: metrics.spacing.medium) {
            Text(number.formatted())
                .font(.posBodyMediumBold)
                .foregroundStyle(Color.posOnPrimaryContainer)
                .frame(width: badgeSize, height: badgeSize)
                .background(Circle().fill(Color.posPrimaryContainer))

            Text(text)
                .font(.posBodyLargeRegular())
                .foregroundStyle(Color.posOnSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

private extension POSOnboardingGuideView {
    enum Localization {
        static let startSelling = NSLocalizedString(
            "pos.onboardingGuide.startSellingButton",
            value: "Start selling",
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
/// Opens the guide from the app's Debug Panel until the guide is shown when POS opens (WOOMOB-4727).
public struct POSOnboardingGuideDebugView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var currentStep: POSOnboardingGuideStep = .checkout

    private let onStartSelling: (_ stepNumber: Int) -> Void
    private let onExit: (_ stepNumber: Int) -> Void

    public init(onStartSelling: @escaping (_ stepNumber: Int) -> Void, onExit: @escaping (_ stepNumber: Int) -> Void) {
        self.onStartSelling = onStartSelling
        self.onExit = onExit
    }

    public var body: some View {
        POSOnboardingGuideView(currentStep: $currentStep,
                               onStartSelling: { onStartSelling(currentStep.rawValue + 1) },
                               onExit: { onExit(currentStep.rawValue + 1) })
            .environment(\.posLayoutScale, horizontalSizeClass == .compact ? .compact : .regular)
    }
}

private struct POSOnboardingGuidePreview: View {
    @State var currentStep: POSOnboardingGuideStep

    var body: some View {
        POSOnboardingGuideView(currentStep: $currentStep, onStartSelling: {}, onExit: {})
            .environment(\.horizontalSizeClass, .compact)
            .environment(\.posLayoutScale, .compact)
    }
}

#Preview("Step 1, smallest phone") {
    POSOnboardingGuidePreview(currentStep: .checkout)
        .posPreviewSmallestPhone()
}

#Preview("Step 2") {
    POSOnboardingGuidePreview(currentStep: .oneStore)
}

#Preview("Step 3, smallest phone") {
    POSOnboardingGuidePreview(currentStep: .howASaleWorks)
        .posPreviewSmallestPhone()
}

#Preview("Step 3, dark") {
    POSOnboardingGuidePreview(currentStep: .howASaleWorks)
        .preferredColorScheme(.dark)
}

#Preview("Accessibility text, smallest phone") {
    POSOnboardingGuidePreview(currentStep: .oneStore)
        .posPreviewSmallestPhone()
        .dynamicTypeSize(.accessibility3)
}
#endif
