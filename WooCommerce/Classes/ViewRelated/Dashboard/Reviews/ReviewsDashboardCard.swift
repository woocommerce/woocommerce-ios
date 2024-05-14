import SwiftUI
import struct Yosemite.DashboardCard

/// SwiftUI view for the Reviews dashboard card
///
struct ReviewsDashboardCard: View {
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
