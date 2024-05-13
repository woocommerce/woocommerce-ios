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
            Text(DashboardCard.CardType.reviews.name)
                .headlineStyle()
            Spacer()
            Menu {
                Button(Localization.hideCard) {
                    // TODO
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(Color.secondary)
                    .padding(.leading, Layout.padding)
                    .padding(.vertical, Layout.hideIconVerticalPadding)
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
        static let viewAll = NSLocalizedString(
            "reviewsDashboardCard.viewAll",
            value: "View all reviews",
            comment: "Button to navigate to Reviews list screen."
        )
    }
}
