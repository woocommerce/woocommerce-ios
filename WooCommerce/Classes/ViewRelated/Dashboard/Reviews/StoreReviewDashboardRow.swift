import StoreDesignSystem
import SwiftUI

struct StoreReviewDashboardRow: View {
    let viewModel: ReviewViewModel
    let highlightsUnread: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: StoreSpacing.s0) {
                HStack(alignment: .top, spacing: StoreSpacing.s5) {
                    StoreIcon.MessageLines.solid.image(size: .largeIncreased)
                        .foregroundStyle(highlightsUnread ? .storeSecondary : .storeOnSurface)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: StoreSpacing.s2) {
                        if let subject = viewModel.subject {
                            Text(subject)
                                .storeTextStyle(.titleMedium)
                        }

                        Text(reviewText)
                            .storeTextStyle(.bodyMedium)
                            .lineLimit(2)

                        if viewModel.review.rating > 0 {
                            HStack(spacing: StoreSpacing.s2) {
                                ForEach(0..<viewModel.review.rating, id: \.self) { _ in
                                    StoreIcon.Star.solid.image(size: .small)
                                }
                            }
                            .accessibilityLabel(Localization.rating(viewModel.review.rating))
                        }
                    }
                    .multilineTextAlignment(.leading)

                    Spacer(minLength: StoreSpacing.s0)
                }
                .foregroundStyle(.storeOnSurface)
                .padding(.horizontal, StorePadding.p5)
                .padding(.vertical, StorePadding.p3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)

                StoreDivider(variant: .inset)
            }
        }
        .buttonStyle(.plain)
    }

    private var reviewText: AttributedString {
        var review = AttributedString(viewModel.snippetData.reviewText)
        review.foregroundColor = .storeOnSurface
        guard viewModel.shouldDisplayStatus else { return review }

        var pending = AttributedString(viewModel.snippetData.pendingReviewsText)
        pending.foregroundColor = .storeOnSecondaryContainer
        var divider = AttributedString(viewModel.snippetData.dot)
        divider.foregroundColor = .storeOnSurface
        return pending + divider + review
    }
}

private extension StoreReviewDashboardRow {
    enum Localization {
        static func rating(_ count: Int) -> String {
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "storeReviewDashboardRow.rating",
                    value: "%1$d out of 5 stars",
                    comment: "Accessibility label for the star rating on a review in the Dashboard card"
                ),
                count
            )
        }
    }
}
