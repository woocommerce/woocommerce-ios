import SwiftUI
import struct Yosemite.DashboardCard
import struct Yosemite.ProductReview

/// SwiftUI view for the Reviews dashboard card
///
struct ReviewsDashboardCard: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    @State private var showingAllReviews: Bool = false

    private let viewModel: ReviewsDashboardCardViewModel

    init(viewModel: ReviewsDashboardCardViewModel) {
        self.viewModel = viewModel
    }


    var body: some View {
        VStack(alignment: .leading, spacing: Layout.padding) {
            header
                .padding(.horizontal, Layout.padding)

            reviewsFilterBar
                .padding(.horizontal, Layout.padding)
                .redacted(reason: viewModel.syncingData ? [.placeholder] : [])
                .shimmering(active: viewModel.syncingData)
            Divider()
                .redacted(reason: viewModel.syncingData ? [.placeholder] : [])
                .shimmering(active: viewModel.syncingData)

            if viewModel.data.isNotEmpty {
                ForEach(Array(viewModel.data.enumerated()), id: \.element.review.reviewID) { index, reviewViewModel in
                    ReviewRow(for: reviewViewModel, isLastItem: index == viewModel.data.count-1)
                }
                .redacted(reason: viewModel.syncingData ? [.placeholder] : [])
                .shimmering(active: viewModel.syncingData)

                Divider()

                viewAllReviewsButton
                    .padding(.horizontal, Layout.padding)
                    .redacted(reason: viewModel.syncingData ? [.placeholder] : [])
                    .shimmering(active: viewModel.syncingData)
            }
        }
        .padding(.vertical, Layout.padding)
        .background(Color(.listForeground(modal: false)))
        .clipShape(RoundedRectangle(cornerSize: Layout.cornerSize))
        .padding(.horizontal, Layout.padding)
        LazyNavigationLink(destination: ReviewsView(siteID: viewModel.siteID), isActive: $showingAllReviews) {
            EmptyView()
        }
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
            .disabled(viewModel.syncingData)
        }
    }

    var reviewsFilterBar: some View {
        HStack {
            AdaptiveStack(horizontalAlignment: .leading) {
                Text(Localization.status)
                    .foregroundStyle(Color(.text))
                    .subheadlineStyle()

                Text("All") // TODO: dynamically change based on filter selection
                    .subheadlineStyle()
            }
            Spacer()

            Menu {
                ForEach(viewModel.filters, id: \.self) { filter in
                    Button {
                        // TODO
                    } label: {
                        SelectableItemRow(title: filter.title, selected: false)
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .foregroundStyle(Color.secondary)
            }
        }
    }

    func ReviewRow(for viewModel: ReviewViewModel, isLastItem: Bool) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Image(systemName: "bubble.fill")
                .foregroundStyle(viewModel.review.status == .hold ? Color.secondary : Color(.wooCommercePurple(.shade60)))
                .padding(.horizontal, Layout.padding)
                .padding(.vertical, Layout.cardPadding)


            VStack(alignment: .leading) {
                if let subject = viewModel.subject {
                    Text(subject)
                        .bodyStyle()
                        .padding(.trailing, Layout.padding)
                }

                if let snippet = viewModel.snippet {
                    Text(snippet.string)
                        .lineLimit(2)
                        .subheadlineStyle()
                        .padding(.trailing, Layout.padding)
                }

                if viewModel.review.rating > 0 {
                    HStack(spacing: Layout.starRatingSpacing) {
                        ForEach(0..<viewModel.review.rating, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .resizable()
                                .frame(width: Constants.starSize * scale, height: Constants.starSize * scale)
                        }
                    }
                }

                Divider()
                    .padding(.vertical, Layout.dividerSpacing)
                    .renderedIf(!isLastItem)
            }
        }
    }

    var viewAllReviewsButton: some View {
        Button {
            showingAllReviews = true
        } label: {
            HStack {
                Text(Localization.viewAll)
                Spacer()
                Image(systemName: "chevron.forward")
                    .foregroundStyle(Color(.tertiaryLabel))
            }
        }
        .disabled(viewModel.syncingData)
    }
}

private extension ReviewsDashboardCard {
    enum Layout {
        static let padding: CGFloat = 16
        static let cardPadding: CGFloat = 4
        static let cornerSize = CGSize(width: 8.0, height: 8.0)
        static let hideIconVerticalPadding: CGFloat = 8
        static let starRatingSpacing: CGFloat = 4
        static let dividerSpacing: CGFloat = 4
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
        static let pendingReview = NSLocalizedString(
            "reviewsDashboardCard.pendingReview",
            value: "Pending review",
            comment: "Additional label on a review when its status is hold."
        )
        static let viewAll = NSLocalizedString(
            "reviewsDashboardCard.viewAll",
            value: "View all reviews",
            comment: "Button to navigate to Reviews list screen."
        )
        static let completeAuthorText = NSLocalizedString(
            "reviewsDashboardCard.completeAuthorText",
            value: "%@ left a review on %@",
            comment: "Text displayed when the author of a review is known."
        )
        static let incompleteAuthorText = NSLocalizedString(
            "reviewsDashboardCard.incompleteAuthorText",
            value: "A customer left a review on %@",
            comment: "Text displayed when the author of a review is unknown."
        )
    }
}

#Preview {
    ReviewsDashboardCard(viewModel: ReviewsDashboardCardViewModel(siteID: 1))
}
