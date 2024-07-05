import SwiftUI
import struct Yosemite.DashboardCard
import struct Yosemite.GoogleAdsCampaign

struct GoogleAdsDashboardCard: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

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
        VStack(alignment: .leading, spacing: Layout.padding) {
            header
                .padding(.horizontal, Layout.padding)

            if viewModel.syncingError != nil {
                DashboardCardErrorView {
                    ServiceLocator.analytics.track(event: .DynamicDashboard.cardRetryTapped(type: .googleAds))
                    Task {
                        await viewModel.fetchLastCampaign()
                    }
                }
            } else if let campaign = viewModel.lastCampaign {
                GoogleAdsCampaignDetailView(campaign: campaign,
                                            stats: viewModel.lastCampaignStats)
                    .padding(.horizontal, Layout.padding)
                    .onTapGesture {
                        onShowAllCampaigns()
                    }
                    .redacted(reason: viewModel.syncingData ? .placeholder : [])
                    .shimmering(active: viewModel.syncingData)
            } else {
                // Introduction about Google Ads
                noCampaignView
                    .padding(.horizontal, Layout.padding)
                    .redacted(reason: viewModel.syncingData ? .placeholder : [])
                    .shimmering(active: viewModel.syncingData)
            }

            // Create campaign button
            createCampaignButton
                .padding(.horizontal, Layout.padding)
                .redacted(reason: viewModel.syncingData ? .placeholder : [])
                .shimmering(active: viewModel.syncingData)

            // Show All Campaigns button
            VStack(spacing: Layout.padding) {
                Divider()
                    .padding(.leading, Layout.padding)
                showAllCampaignsButton
                    .padding(.horizontal, Layout.padding)
            }
            .redacted(reason: viewModel.syncingData ? .placeholder : [])
            .shimmering(active: viewModel.syncingData)
            .renderedIf(viewModel.shouldShowShowAllCampaignsButton)
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

    var noCampaignView: some View {
        HStack(alignment: .top) {
            Image(uiImage: .googleLogo)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Layout.imageSize * scale, height: Layout.imageSize * scale)

            VStack(alignment: .leading) {
                Text(Localization.NoCampaign.title)
                    .headlineStyle()
                Text(Localization.NoCampaign.subtitle)
                    .subheadlineStyle()
            }
        }
        .padding(Layout.contentPadding)
        .background(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .fill(Color(uiColor: .init(light: UIColor.clear,
                                           dark: UIColor.systemGray5)))
        )
        .overlay {
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(Color(uiColor: .secondaryButtonDownBorder), lineWidth: Layout.strokeWidth)
        }
    }

    var createCampaignButton: some View {
        Button(Localization.createCampaign) {
            onCreateNewCampaign()
        }
        .buttonStyle(SecondaryButtonStyle())
    }

    var showAllCampaignsButton: some View {
        Button {
            onShowAllCampaigns()
        } label: {
            HStack(spacing: 0) {
                Text(Localization.viewAll)
                    .fontWeight(.regular)
                    .foregroundStyle(Color.accentColor)
                    .bodyStyle()

                Spacer()

                // Chevron icon
                Image(uiImage: .chevronImage)
                    .flipsForRightToLeftLayoutDirection(true)
                    .foregroundStyle(Color(.textTertiary))
            }
        }
    }
}

private extension GoogleAdsDashboardCard {
    enum Layout {
        static let padding: CGFloat = 16
        static let cornerSize = CGSize(width: cornerRadius, height: cornerRadius)
        static let hideIconVerticalPadding: CGFloat = 8
        static let contentPadding: CGFloat = 16
        static let strokeWidth: CGFloat = 1
        static let cornerRadius: CGFloat = 8
        static let imageSize: CGFloat = 44
    }

    enum Localization {
        static let hideCard = NSLocalizedString(
            "googleAdsDashboardCard.hideCard",
            value: "Hide Google Ads",
            comment: "Menu item to dismiss the Google Ads campaigns section on the Dashboard screen"
        )
        static let viewAll = NSLocalizedString(
            "googleAdsDashboardCard.viewAll",
            value: "View all campaigns",
            comment: "Button to navigate to the Google Ads campaign dashboard."
        )
        static let createCampaign = NSLocalizedString(
            "googleAdsDashboardCard.createCampaign",
            value: "Create Campaign",
            comment: "Button that when tapped will launch create Google Ads campaign flow."
        )
        enum NoCampaign {
            static let title = NSLocalizedString(
                "googleAdsDashboardCard.noCampaign.title",
                value: "Boost store traffic and sales with Google Ads",
                comment: "Title label on the Google Ads campaigns section on the Dashboard screen"
            )
            static let subtitle = NSLocalizedString(
                "googleAdsDashboardCard.noCampaign.subtitle",
                value: "Create an ad campaign to promote your products across Google Search, Shopping, YouTube, Gmail, and the Display Network.",
                comment: "Subtitle label on the Google Ads campaigns section on the Dashboard screen"
            )
        }
    }
}

#Preview {
    GoogleAdsDashboardCard(viewModel: GoogleAdsDashboardCardViewModel(siteID: 135),
                           onCreateNewCampaign: {},
                           onShowAllCampaigns: {})
}
