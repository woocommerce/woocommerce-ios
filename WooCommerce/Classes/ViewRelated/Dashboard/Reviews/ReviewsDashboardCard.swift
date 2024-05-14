import SwiftUI
import struct Yosemite.DashboardCard
import struct Yosemite.ProductReview

/// SwiftUI view for the Reviews dashboard card
///
struct ReviewsDashboardCard: View {
    private let viewModel: ReviewsDashboardCardViewModel

    let dummyData: [ProductReview] = [
        ProductReview(siteID: 1, reviewID: 1, productID: 1, dateCreated: Date(),
                      statusKey: "", reviewer: "Sherlock", reviewerEmail: "", reviewerAvatarURL: "",
                      review: "The best product in the whole world. This is meant to be really long to be more than two lines",
                      rating: 5, verified: true),
        ProductReview(siteID: 1, reviewID: 2, productID: 1, dateCreated: Date(),
                      statusKey: "", reviewer: "Holmes", reviewerEmail: "", reviewerAvatarURL: "",
                      review: "Amazing!", rating: 5, verified: true),
        ProductReview(siteID: 1, reviewID: 3, productID: 1, dateCreated: Date(),
                      statusKey: "", reviewer: "Agatha", reviewerEmail: "", reviewerAvatarURL: "",
                      review: "Great!", rating: 5, verified: true)
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

            ForEach(Array(dummyData.enumerated()), id: \.element.reviewID) { index, review in
                ReviewRow(for: review)

                if index != dummyData.count-1 {
                    Divider()
                }
            }
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
            .disabled(viewModel.syncingData)
        }
    }

    var reviewsFilterBar: some View {
        HStack {
            AdaptiveStack(horizontalAlignment: .leading) {
                Text(Localization.status)
                    .foregroundStyle(Color(.text))
                    .subheadlineStyle()

                Text("All")
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

    func ReviewRow(for review: ProductReview) -> some View {
        HStack {
            Image(systemName: "bubble.fill")
                .foregroundStyle(Color.secondary)

            VStack(alignment: .leading) {
                Text("Neil Gaiman left a review on Fallen Angel Candelabra")
                Text(review.review)
                    .lineLimit(2)
                HStack {
                    ForEach(0..<abs(review.rating), id: \.self) { _ in
                        Image(systemName: "star.fill")
                    }
                }
            }
        }
    }
}

private extension ReviewsDashboardCard {
    enum Layout {
        static let padding: CGFloat = 16
        static let cornerSize = CGSize(width: 8.0, height: 8.0)
        static let hideIconVerticalPadding: CGFloat = 8
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
