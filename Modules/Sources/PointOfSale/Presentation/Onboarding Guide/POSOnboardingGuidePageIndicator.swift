import SwiftUI

/// Page dots for the onboarding guide. VoiceOver users change the step by swiping up or down on it,
/// and hear the new step's title.
struct POSOnboardingGuidePageIndicator: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding var currentStep: POSOnboardingGuideStep

    private static let dotSize: CGFloat = 8
    private let steps = POSOnboardingGuideStep.allCases

    var body: some View {
        HStack(spacing: metrics.spacing.small) {
            ForEach(steps) { step in
                Circle()
                    .fill(step == currentStep ? Color.posPrimary : Color.posOnSurfaceVariantLowest)
                    .frame(width: Self.dotSize, height: Self.dotSize)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Localization.label)
        .accessibilityValue(String.localizedStringWithFormat(Localization.value, currentStep.title, currentStep.rawValue + 1, steps.count))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                show(POSOnboardingGuideStep(rawValue: currentStep.rawValue + 1))
            case .decrement:
                show(POSOnboardingGuideStep(rawValue: currentStep.rawValue - 1))
            @unknown default:
                break
            }
        }
    }

    /// `nil` past the first or last step, where the step stays as it is.
    private func show(_ step: POSOnboardingGuideStep?) {
        guard let step else {
            return
        }
        withAnimation(reduceMotion ? nil : .default) {
            currentStep = step
        }
    }
}

private extension POSOnboardingGuidePageIndicator {
    enum Localization {
        static let label = NSLocalizedString(
            "pos.onboardingGuide.pageIndicator.label",
            value: "Page",
            comment: "Accessibility label of the page dots in the POS onboarding guide."
        )
        static let value = NSLocalizedString(
            "pos.onboardingGuide.pageIndicator.stepValue",
            value: "%1$@, %2$d of %3$d",
            comment: "Accessibility value of the page dots in the POS onboarding guide, read after changing the page. " +
                "%1$@ is the title of the current page, %2$d is its number, %3$d is the number of pages. " +
                "Example: One store, online and in person, 2 of 3"
        )
    }
}

#if DEBUG
#Preview {
    VStack(spacing: POSMetrics.regular.spacing.large) {
        POSOnboardingGuidePageIndicator(currentStep: .constant(.checkout))
        POSOnboardingGuidePageIndicator(currentStep: .constant(.oneStore))
        POSOnboardingGuidePageIndicator(currentStep: .constant(.howASaleWorks))
    }
}
#endif
