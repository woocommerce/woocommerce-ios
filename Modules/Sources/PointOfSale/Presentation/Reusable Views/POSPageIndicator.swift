import SwiftUI

/// Page dots for paged content. VoiceOver users change the page by swiping up or down on them.
struct POSPageIndicator: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let pageCount: Int
    @Binding var currentPage: Int
    /// Read by VoiceOver with the page number, e.g. the page title.
    var accessibilityPageName: ((Int) -> String)?

    private static let dotSize: CGFloat = 8

    var body: some View {
        HStack(spacing: metrics.spacing.small) {
            ForEach(0..<pageCount, id: \.self) { page in
                Circle()
                    .fill(page == currentPage ? Color.posPrimary : Color.posOnSurfaceVariantLowest)
                    .frame(width: Self.dotSize, height: Self.dotSize)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Localization.label)
        .accessibilityValue(accessibilityValue)
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

    private var accessibilityValue: String {
        let position = String.localizedStringWithFormat(Localization.position, currentPage + 1, pageCount)
        guard let accessibilityPageName else {
            return position
        }
        return String.localizedStringWithFormat(Localization.namedPosition, accessibilityPageName(currentPage), position)
    }

    private func showPage(_ page: Int) {
        guard (0..<pageCount).contains(page) else {
            return
        }
        withAnimation(reduceMotion ? nil : .default) {
            currentPage = page
        }
    }
}

private extension POSPageIndicator {
    enum Localization {
        static let label = NSLocalizedString(
            "pos.pageIndicator.label",
            value: "Page",
            comment: "Accessibility label of the page dots in POS."
        )
        static let position = NSLocalizedString(
            "pos.pageIndicator.position",
            value: "%1$d of %2$d",
            comment: "Accessibility value of the page dots in POS. %1$d is the current page number, %2$d is the number of pages. Example: 1 of 3"
        )
        static let namedPosition = NSLocalizedString(
            "pos.pageIndicator.namedPosition",
            value: "%1$@, %2$@",
            comment: "Accessibility value of the page dots in POS when pages have names. " +
                "%1$@ is the page name, %2$@ is its position, e.g. \"2 of 3\". Example: One store for every sale, 2 of 3"
        )
    }
}

#if DEBUG
#Preview {
    POSPageIndicator(pageCount: 3, currentPage: .constant(1))
}
#endif
