import SwiftUI
import struct Yosemite.DashboardCard
import struct Yosemite.ProductReview

/// SwiftUI view for the Reviews dashboard card
///
struct ReviewsDashboardCard: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    @ObservedObject private var viewModel: ReviewsDashboardCardViewModel
    private let onViewAllReviews: (() -> Void)
    private let onViewReviewDetail: ((_ review: ReviewViewModel) -> Void)

    init(viewModel: ReviewsDashboardCardViewModel,
         onViewAllReviews: @escaping () -> Void,
         onViewReviewDetail: @escaping (_ review: ReviewViewModel) -> Void) {
        self.viewModel = viewModel
        self.onViewAllReviews = onViewAllReviews
        self.onViewReviewDetail = onViewReviewDetail
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.padding) {
            header
                .padding(.horizontal, Layout.padding)

            reviewsFilterBar
                .padding(.horizontal, Layout.padding)
                .redacted(reason: viewModel.showLoadingAnimation ? [.placeholder] : [])
                .shimmering(active: viewModel.showLoadingAnimation)
            Divider()

            if viewModel.showLoadingAnimation || viewModel.data.isNotEmpty {
                ForEach(viewModel.data, id: \.review.reviewID) { reviewViewModel in
                    reviewRow(for: reviewViewModel,
                              isLastItem: reviewViewModel == viewModel.data.last)
                }
                .redacted(reason: viewModel.showLoadingAnimation ? [.placeholder] : [])
                .shimmering(active: viewModel.showLoadingAnimation)
            }

            Divider()

            viewAllReviewsButton
                .padding(.horizontal, Layout.padding)
                .redacted(reason: viewModel.showLoadingAnimation ? [.placeholder] : [])
                .shimmering(active: viewModel.showLoadingAnimation)
        }
        .padding(.vertical, Layout.padding)
        .background(Color(.listForeground(modal: false)))
        .clipShape(RoundedRectangle(cornerSize: Layout.cornerSize))
        .padding(.horizontal, Layout.padding)
    }
}

private extension ReviewsDashboardCard {
    var header: some View {
        HStack {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(Color.secondary)
                .headlineStyle()
                .renderedIf(viewModel.syncingError != nil)
            Text(DashboardCard.CardType.reviews.name)
                .headlineStyle()
            Spacer()
            Menu {
                Button(Localization.hideCard) {
                    viewModel.dismissReviews()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(Color.secondary)
                    .padding(.leading, Layout.padding)
                    .padding(.vertical, Layout.hideIconVerticalPadding)
            }
            .disabled(viewModel.showLoadingAnimation)
        }
    }

    var reviewsFilterBar: some View {
        HStack {
            AdaptiveStack(horizontalAlignment: .leading) {
                Text(Localization.status)
                    .foregroundStyle(Color(.text))
                    .subheadlineStyle()

                Text(viewModel.currentFilter.title)
                    .subheadlineStyle()
            }
            .redacted(reason: viewModel.switchingStatus ? [.placeholder] : [])
            .shimmering(active: viewModel.switchingStatus)
            Spacer()

            Menu {
                ForEach(viewModel.filters, id: \.self) { filter in
                    Button {
                        Task {
                            await viewModel.filterReviews(by: filter)
                        }
                    } label: {
                        SelectableItemRow(title: filter.title, selected: viewModel.currentFilter == filter)
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .foregroundStyle(Color.secondary)
            }
        }
    }

    func reviewRow(for viewModel: ReviewViewModel, isLastItem: Bool) -> some View {
        Button {
            onViewReviewDetail(viewModel)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: Layout.padding) {
                Image(systemName: "bubble.fill")
                    .foregroundStyle(
                        viewModel.notification == nil || viewModel.notification?.read == true
                        ? Color.secondary
                        : Color(.wooCommercePurple(.shade60))
                    )

                VStack(alignment: .leading, spacing: Layout.padding) {
                    VStack(alignment: .leading) {
                        if let subject = viewModel.subject {
                            Text(subject)
                                .multilineTextAlignment(.leading)
                                .bodyStyle()
                        }

                        reviewText(text: viewModel.snippetData.reviewText,
                                   pendingText: viewModel.snippetData.pendingReviewsText,
                                   divider: viewModel.snippetData.dot,
                                   textColor: viewModel.snippetData.textColor,
                                   accentColor: viewModel.snippetData.accentColor,
                                   shouldDisplayStatus: viewModel.shouldDisplayStatus)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .subheadlineStyle()

                        if viewModel.review.rating > 0 {
                            HStack(spacing: Layout.starRatingSpacing) {
                                ForEach(0..<viewModel.review.rating, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .resizable()
                                        .frame(width: Constants.starSize * scale, height: Constants.starSize * scale)
                                        .foregroundColor(Color(.label))
                                }
                            }
                        }
                    }
                    .padding(.trailing, Layout.padding)

                    Divider()
                        .renderedIf(!isLastItem)
                }
            }
            .padding(.leading, Layout.padding)
        }
    }

    func reviewText(text: String,
                    pendingText: String,
                    divider: String,
                    textColor: UIColor,
                    accentColor: UIColor,
                    shouldDisplayStatus: Bool) -> some View {

        var pendingAttributedString: AttributedString {
            var result = AttributedString(pendingText)
            result.foregroundColor = Color(uiColor: accentColor)
            return result
        }

        var dividerAttributedString: AttributedString {
            var result = AttributedString(divider)
            result.foregroundColor = Color(uiColor: textColor)
            return result
        }

        var reviewAttributedString: AttributedString {
            var result = AttributedString(text)
            result.foregroundColor = Color(uiColor: textColor)
            return result
        }

        var reviewText: AttributedString {
            if shouldDisplayStatus {
                return pendingAttributedString + dividerAttributedString + reviewAttributedString
            } else {
                return reviewAttributedString
            }
        }

        return Text(reviewText)
    }

    var viewAllReviewsButton: some View {
        Button {
            onViewAllReviews()
        } label: {
            HStack {
                Text(Localization.viewAll)
                Spacer()
                Image(systemName: "chevron.forward")
                    .foregroundStyle(Color(.tertiaryLabel))
            }
        }
        .disabled(viewModel.showLoadingAnimation)
    }
}

private extension ReviewsDashboardCard {
    enum Layout {
        static let padding: CGFloat = 16
        static let cornerSize = CGSize(width: 8.0, height: 8.0)
        static let hideIconVerticalPadding: CGFloat = 8
        static let starRatingSpacing: CGFloat = 4
    }

    enum Constants {
        static let starSize: CGFloat = 10
    }

    enum Localization {
        static let hideCard = NSLocalizedString(
            "reviewsDashboardCard.hideCard",
            value: "Hide Reviews",
            comment: "Menu item to dismiss the Reviews card on the Dashboard screen"
        )
        static let status = NSLocalizedString(
            "reviewsDashboardCard.status",
            value: "Status",
            comment: "Status label on the Reviews card's filter area."
        )
        static let viewAll = NSLocalizedString(
            "reviewsDashboardCard.viewAll",
            value: "View all reviews",
            comment: "Button to navigate to Reviews list screen."
        )
    }
}

#Preview {
    ReviewsDashboardCard(viewModel: ReviewsDashboardCardViewModel(siteID: 1),
                         onViewAllReviews: { },
                         onViewReviewDetail: { _ in })
}
