import SwiftUI

/// Full-screen guide shown on iPhone when POS opens, until the merchant taps Start selling.
/// It has no close button: the merchant either starts selling or exits POS.
struct POSOnboardingGuideView: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric private var contentMaxWidth = POSStatusButtonsLayout.maxWidth
    @State private var tallestStepHeight: CGFloat = 0

    @Binding var currentStep: POSOnboardingGuideStep
    let onStartSelling: () -> Void
    let onExit: () -> Void

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: metrics.spacing.none) {
                TabView(selection: $currentStep) {
                    ForEach(POSOnboardingGuideStep.allCases) { step in
                        page(for: step)
                            .tag(step)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .accessibilityIdentifier("pos-onboarding-guide")

                POSOnboardingGuidePageIndicator(currentStep: $currentStep)
                    .posPadding(.top, \.medium)
                    .accessibilityIdentifier("pos-onboarding-guide-page-indicator")

                buttons
                    // With large text, titles wrap instead of being truncated.
                    .fixedSize(horizontal: false, vertical: true)
                    .posStatusButtonsWidth(addsHorizontalPadding: false)
                    .posPhoneBottomButtonPadding(bottom: POSCompactFooterLayout.bottomPadding(safeAreaInset: geometry.safeAreaInsets.bottom,
                                                                                             metrics: metrics))
            }
        }
        .background(Color.posSurface.ignoresSafeArea())
        .interactiveDismissDisabled()
    }

    /// The hero gives its space to the text in landscape and with accessibility text sizes.
    private var showsHero: Bool {
        verticalSizeClass != .compact && !dynamicTypeSize.isAccessibilitySize
    }

    /// Titles stay in place while swiping: every page takes the height of the tallest step, or, when that doesn't fit,
    /// every step scrolls from the top, so no step scrolls into empty space.
    private func page(for step: POSOnboardingGuideStep) -> some View {
        GeometryReader { geometry in
            let tallestStepFits = tallestStepHeight <= geometry.size.height
            ScrollView(.vertical) {
                POSOnboardingGuideStepView(step: step, showsHero: showsHero)
                    .frame(maxWidth: .infinity, minHeight: tallestStepFits ? tallestStepHeight : nil, alignment: .top)
                    .background {
                        tallestStepMeasurement
                    }
                    .modifier(PageContentWidth(maxWidth: contentMaxWidth))
                    .frame(minHeight: geometry.size.height, alignment: tallestStepFits ? .center : .top)
            }
            .scrollBounceBehavior(.basedOnSize)
            // Shows that the step continues below.
            .scrollIndicatorsFlash(onAppear: true)
            .scrollIndicatorsFlash(trigger: currentStep)
        }
    }

    private var tallestStepMeasurement: some View {
        ZStack {
            ForEach(POSOnboardingGuideStep.allCases) {
                POSOnboardingGuideStepView(step: $0, showsHero: showsHero)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .hidden()
        .accessibilityHidden(true)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { tallestStepHeight = $0 }
    }

    /// Side by side in landscape, so the buttons leave room for the step.
    private var buttons: some View {
        POSFlowButtonsView(configuration: buttonConfiguration)
            .environment(\.horizontalSizeClass, verticalSizeClass == .compact ? .regular : horizontalSizeClass)
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

private struct PageContentWidth: ViewModifier {
    @Environment(\.posMetrics) private var metrics

    let maxWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
            .posContentPadding(.horizontal, metrics.padding.medium)
    }
}

private struct POSOnboardingGuideStepView: View {
    @Environment(\.posMetrics) private var metrics

    let step: POSOnboardingGuideStep
    let showsHero: Bool

    /// Matches the access control onboarding illustration.
    private static let illustrationSize: CGFloat = 140

    var body: some View {
        VStack(spacing: metrics.spacing.xLarge) {
            if showsHero {
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
                    POSOnboardingGuideSaleSteps()
                        .posPadding(.top, \.small)
                }
            }
            .multilineTextAlignment(.center)
        }
        .fixedSize(horizontal: false, vertical: true)
        .posPadding(.vertical, \.medium)
    }
}

/// The steps of a sale as a row of numbered, equally short labels joined by a line.
/// With accessibility text sizes the labels don't fit side by side, so the steps stack.
private struct POSOnboardingGuideSaleSteps: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let steps = POSOnboardingGuideStep.saleSteps

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: metrics.spacing.medium) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, label in
                    HStack(spacing: metrics.spacing.medium) {
                        badge(number: index + 1)
                        self.label(label)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        } else {
            HStack(alignment: .top, spacing: metrics.spacing.none) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, label in
                    VStack(spacing: metrics.spacing.small) {
                        HStack(spacing: metrics.spacing.none) {
                            connector(visible: index > 0)
                            badge(number: index + 1)
                            connector(visible: index < steps.count - 1)
                        }
                        self.label(label)
                            .posPadding(.horizontal, \.xSmall)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private func badge(number: Int) -> some View {
        POSOnboardingGuideSaleStepBadge(number: number)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.posBodyMediumRegular())
            .foregroundStyle(Color.posOnSurfaceVariantHighest)
    }

    private func connector(visible: Bool) -> some View {
        Rectangle()
            .fill(visible ? Color.posOutlineVariant : .clear)
            .frame(height: Self.connectorHeight)
            .frame(maxWidth: .infinity)
    }

    private static let connectorHeight: CGFloat = 2
}

private struct POSOnboardingGuideSaleStepBadge: View {
    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 32

    let number: Int

    var body: some View {
        Text(number.formatted())
            .font(.posBodyMediumBold)
            .foregroundStyle(Color.posOnPrimaryContainer)
            .frame(width: size, height: size)
            .background(Circle().fill(Color.posPrimaryContainer))
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
