import SwiftUI

/// Shown when the Reviews dashboard card can't show any cards.
struct ReviewsDashboardEmptyView: View {
    let isFiltered: Bool

    var body: some View {
        VStack(alignment: .center, spacing: Layout.defaultSpacing) {
            Image(uiImage: .emptyReviewsImage)
            Text(isFiltered ? Localization.noFilteredReviewsText : Localization.noReviewsText)
                .subheadlineStyle()
        }
        .padding(.all, Layout.defaultSpacing)
    }
}

private extension ReviewsDashboardEmptyView {
    enum Localization {
        static let noReviewsText = NSLocalizedString(
            "mostActiveCouponsEmptyView.noReviewsText",
            value: "No reviews found.",
            comment: "Message shown in the Reviews Dashboard Card if the site has no review"
        )

        static let noFilteredReviewsText = NSLocalizedString(
            "mostActiveCouponsEmptyView.noFilteredReviewsText",
            value: "No reviews match the selected filter, please try changing the filter.",
            comment: "Message shown in the Reviews Dashboard Card if the list is filtered and there is no review."
        )
    }

    enum Layout {
        static let defaultSpacing: CGFloat = 16
    }
}

#Preview {
    ReviewsDashboardEmptyView(isFiltered: false)
}
