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

    let dummyData: [ProductReview] = [
        ProductReview(siteID: 1, reviewID: 1, productID: 1, dateCreated: Date(),
                      statusKey: "approved", reviewer: "Sherlock", reviewerEmail: "", reviewerAvatarURL: "",
                      review: "The best product in the whole world. This is meant to be really long to be more than two lines",
                      rating: 5, verified: true),
        ProductReview(siteID: 1, reviewID: 2, productID: 1, dateCreated: Date(),
                      statusKey: "hold", reviewer: "Holmes", reviewerEmail: "", reviewerAvatarURL: "",
                      review: "Amazing!", rating: 5, verified: true),
        ProductReview(siteID: 1, reviewID: 3, productID: 1, dateCreated: Date(),
                      statusKey: "approved", reviewer: "", reviewerEmail: "", reviewerAvatarURL: "",
                      review: "", rating: 5, verified: true)
    ]

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

            if viewModel.data.isNotEmpty {
                ForEach(Array(viewModel.data.enumerated()), id: \.element.reviewID) { index, review in
                    ReviewRow(for: review, isLastItem: index == dummyData.count-1)
                }
            }
            Divider()
            viewAllReviewsButton
                .padding(.horizontal, Layout.padding)
                .redacted(reason: viewModel.syncingData ? [.placeholder] : [])
                .shimmering(active: viewModel.syncingData)
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

    func ReviewRow(for review: ProductReview, isLastItem: Bool) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Image(systemName: "bubble.fill")
                .foregroundStyle(review.status == .hold ? Color.secondary : Color(.wooCommercePurple(.shade60)))
                .padding(.horizontal, Layout.padding)
                .padding(.vertical, Layout.cardPadding)


            VStack(alignment: .leading) {
                // TODO: use actual product name
                authorText(author: review.reviewer, productName: "Fallen Angel Candelabra")
                    .bodyStyle()
                    .padding(.trailing, Layout.padding)
                reviewText(text: review.review, shouldDisplayStatus: review.status == .hold)
                    .lineLimit(2)
                    .subheadlineStyle()
                    .padding(.trailing, Layout.padding)
                    .renderedIf(review.review.isNotEmpty)
                HStack(spacing: Layout.starRatingSpacing) {
                    ForEach(0..<abs(review.rating), id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .resizable()
                            .frame(width: Constants.starSize * scale, height: Constants.starSize * scale)
                    }
                }

                Divider()
                    .padding(.vertical, Layout.dividerSpacing)
                    .renderedIf(!isLastItem)
            }
        }
    }

    func authorText(author: String, productName: String) -> some View {
        if author.isNotEmpty {
            return Text(String.localizedStringWithFormat(Localization.completeAuthorText, author, productName))
        } else {
            return Text(String.localizedStringWithFormat(Localization.incompleteAuthorText, productName))
        }
    }

    func reviewText(text: String, shouldDisplayStatus: Bool) -> some View {
        if shouldDisplayStatus {
            return Text(Localization.pendingReview).foregroundColor(Color(uiColor: .wooOrange)) +
                Text(" • " + text)
        } else {
            return Text(text)
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
