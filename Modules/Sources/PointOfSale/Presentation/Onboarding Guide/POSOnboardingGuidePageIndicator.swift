import SwiftUI

/// Page dots for the onboarding guide. VoiceOver users change the page by swiping up or down on it.
struct POSOnboardingGuidePageIndicator: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding var currentPage: Int
    let totalPages: Int

    private static let dotSize: CGFloat = 8

    var body: some View {
        HStack(spacing: metrics.spacing.small) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.posPrimary : Color.posOnSurfaceVariantLowest)
                    .frame(width: Self.dotSize, height: Self.dotSize)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Localization.label)
        .accessibilityValue(String.localizedStringWithFormat(Localization.value, currentPage + 1, totalPages))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                showPage(currentPage + 1)
            case .decrement:
                showPage(currentPage - 1)
            @unknown default:
                break
            }
        }
    }

    private func showPage(_ page: Int) {
        guard (0..<totalPages).contains(page) else {
            return
        }
        withAnimation(reduceMotion ? nil : .default) {
            currentPage = page
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
            "pos.onboardingGuide.pageIndicator.value",
            value: "%1$d of %2$d",
            comment: "Accessibility value of the page dots in the POS onboarding guide. " +
                "%1$d is the number of the current page, %2$d is the number of pages. Example: 1 of 3"
        )
    }
}

#if DEBUG
#Preview {
    VStack(spacing: POSMetrics.regular.spacing.large) {
        POSOnboardingGuidePageIndicator(currentPage: .constant(0), totalPages: 3)
        POSOnboardingGuidePageIndicator(currentPage: .constant(1), totalPages: 3)
        POSOnboardingGuidePageIndicator(currentPage: .constant(2), totalPages: 3)
    }
}
#endif
