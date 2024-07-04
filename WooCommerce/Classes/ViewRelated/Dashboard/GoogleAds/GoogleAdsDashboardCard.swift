import SwiftUI
import struct Yosemite.DashboardCard

struct GoogleAdsDashboardCard: View {
    @ObservedObject private var viewModel: GoogleAdsDashboardCardViewModel
    private let onCreateNewCampaign: () -> Void
    private let onShowAllCampaigns: () -> Void

    init(viewModel: GoogleAdsDashboardCardViewModel,
         onCreateNewCampaign: @escaping () -> Void,
         onShowAllCampaigns: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onCreateNewCampaign = onCreateNewCampaign
        self.onShowAllCampaigns = onShowAllCampaigns
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, Layout.padding)
        }
        .padding(.vertical, Layout.padding)
        .background(Color(.listForeground(modal: false)))
        .clipShape(RoundedRectangle(cornerSize: Layout.cornerSize))
        .padding(.horizontal, Layout.padding)
    }
}

private extension GoogleAdsDashboardCard {
    var header: some View {
        HStack {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(Color.secondary)
                .headlineStyle()
                .renderedIf(viewModel.syncingError != nil)
            Text(DashboardCard.CardType.googleAds.name)
                .headlineStyle()
            Spacer()
            Menu {
                Button(Localization.hideCard) {
                    viewModel.dismissCard()
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
}

private extension GoogleAdsDashboardCard {
    enum Layout {
        static let padding: CGFloat = 16
        static let cornerSize = CGSize(width: 8.0, height: 8.0)
        static let hideIconVerticalPadding: CGFloat = 8
        static let dividerPadding = EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0)
    }

    enum Localization {
        static let hideCard = NSLocalizedString(
            "googleAdsDashboardCard.hideCard",
            value: "Hide Google for WooCommerce",
            comment: "Menu item to dismiss the Google for WooCommerce section on the Dashboard screen"
        )
        static let viewAll = NSLocalizedString(
            "googleAdsDashboardCard.viewAll",
            value: "View all campaigns",
            comment: "Button to navigate to the Google Ads campaign dashboard."
        )
    }
}

#Preview {
    GoogleAdsDashboardCard(viewModel: GoogleAdsDashboardCardViewModel(siteID: 135),
                           onCreateNewCampaign: {},
                           onShowAllCampaigns: {})
}
