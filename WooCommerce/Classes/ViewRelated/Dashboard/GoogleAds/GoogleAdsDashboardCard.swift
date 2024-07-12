import SwiftUI
import struct Yosemite.DashboardCard
import struct Yosemite.GoogleAdsCampaign
import struct Yosemite.GoogleAdsCampaignStatsTotals

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

            if viewModel.shouldShowErrorState {
                // Error state
                DashboardCardErrorView {
                    ServiceLocator.analytics.track(event: .DynamicDashboard.cardRetryTapped(type: .googleAds))
                    Task {
                        await viewModel.reloadCard()
                    }
                }
            } else if let stats = viewModel.performanceStats {
                // Total performance stats
                statsView(with: stats)
                    .padding(.horizontal, Layout.padding)
                    .onTapGesture {
                        onShowAllCampaigns()
                    }
                    .redacted(reason: viewModel.syncingData ? .placeholder : [])
                    .shimmering(active: viewModel.syncingData)
            } else {
                // Empty state
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
                .renderedIf(viewModel.shouldShowCreateCampaignButton)

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
        .onAppear {
            viewModel.onViewAppear()
        }
    }
}

private extension GoogleAdsDashboardCard {
    var header: some View {
        HStack {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(Color.secondary)
                .headlineStyle()
                .renderedIf(viewModel.shouldShowErrorState)
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
                    .padding(.vertical, Layout.contentVerticalPadding)
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
        .padding(Layout.padding)
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

    func statsView(with stats: GoogleAdsCampaignStatsTotals) -> some View {
        // campaign stats
        AdaptiveStack(horizontalAlignment: .leading, verticalAlignment: .center, spacing: Layout.padding) {
            VStack {
                // Logo image
                Image(uiImage: .googleLogo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Layout.imageSize * scale, height: Layout.imageSize * scale)
                Spacer()
            }
            VStack(alignment: .leading, spacing: Layout.padding) {
                HStack {
                    // Title
                    Text(Localization.Stats.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()

                    // disclosure indicator
                    Image(systemName: "chevron.forward")
                        .foregroundColor(.secondary)
                        .font(.headline)
                }

                AdaptiveStack {
                    // campaign total impressions
                    VStack(alignment: .leading, spacing: Layout.contentVerticalPadding) {
                        Text(Localization.Stats.impressions)
                            .subheadlineStyle()
                        Text("\(stats.impressions ?? 0)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.init(UIColor.text))
                    }
                    .fixedSize()
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // campaign total clicks
                    VStack(alignment: .leading, spacing: Layout.contentVerticalPadding) {
                        Text(Localization.Stats.clicks)
                            .subheadlineStyle()
                        Text("\(stats.clicks ?? 0)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.init(UIColor.text))
                    }
                    .fixedSize()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Layout.padding)
        .background(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .fill(Color(uiColor: .init(light: UIColor.clear,
                                           dark: UIColor.systemGray5)))
        )
        .overlay {
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(Color(uiColor: .separator), lineWidth: Layout.strokeWidth)
        }
        .padding(Layout.strokeWidth)
    }
}

private extension GoogleAdsDashboardCard {
    enum Layout {
        static let padding: CGFloat = 16
        static let cornerSize = CGSize(width: cornerRadius, height: cornerRadius)
        static let contentVerticalPadding: CGFloat = 8
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
                value: "Drive sales and generate more traffic with Google Ads",
                comment: "Title label on the Google Ads campaigns section on the Dashboard screen"
            )
            static let subtitle = NSLocalizedString(
                "googleAdsDashboardCard.noCampaign.details",
                value: "Promote your products across Google Search, Shopping, Youtube, Gmail, and more.",
                comment: "Subtitle label on the Google Ads campaigns section on the Dashboard screen"
            )
        }
        enum Stats {
            static let title = NSLocalizedString(
                "googleAdsDashboardCard.stats.title",
                value: "Paid campaign performance",
                comment: "Title label for the Google Ads paid campaign performance section"
            )
            static let impressions = NSLocalizedString(
                "googleAdsDashboardCard.stats.totalImpressions",
                value: "Impressions",
                comment: "Title label for the total impressions of Google Ads paid campaigns"
            )
            static let clicks = NSLocalizedString(
                "googleAdsDashboardCard.stats.totalClicks",
                value: "Clicks",
                comment: "Title label for the total clicks of Google Ads paid campaigns"
            )
        }
    }
}

#Preview {
    GoogleAdsDashboardCard(viewModel: GoogleAdsDashboardCardViewModel(siteID: 135),
                           onCreateNewCampaign: {},
                           onShowAllCampaigns: {})
}
