import StoreDesignSystem
import SwiftUI
import struct Yosemite.DashboardCard
import struct Yosemite.GoogleAdsCampaign
import struct Yosemite.GoogleAdsCampaignStatsTotals

struct StoreGoogleAdsDashboardCard: View {
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
        StoreDashboardCardSurface {
            VStack(alignment: .leading, spacing: StoreSpacing.s0) {
                header

                if viewModel.shouldShowErrorState {
                    errorState
                } else {
                    VStack(alignment: .leading, spacing: StoreSpacing.s3) {
                        if let stats = viewModel.performanceStats {
                            Button(action: onShowAllCampaigns) {
                                statsView(with: stats)
                            }
                            .buttonStyle(.plain)
                        } else {
                            noCampaignView
                        }

                        StoreButton(Localization.createCampaign,
                                    variant: .outlined,
                                    isFullWidth: true,
                                    action: onCreateNewCampaign)
                            .renderedIf(viewModel.shouldShowCreateCampaignButton)
                    }
                    .redacted(reason: viewModel.syncingData ? .placeholder : [])
                    .shimmering(active: viewModel.syncingData)
                    .padding(.horizontal, StorePadding.p5)
                    .padding(.bottom, StorePadding.p5)

                    StoreDashboardCardFooterAction(Localization.viewAll,
                                                   isDisabled: viewModel.syncingData,
                                                   action: onShowAllCampaigns)
                        .redacted(reason: viewModel.syncingData ? .placeholder : [])
                        .shimmering(active: viewModel.syncingData)
                        .renderedIf(viewModel.shouldShowShowAllCampaignsButton)
                }
            }
        }
        .onAppear(perform: viewModel.onViewAppear)
    }
}

private extension StoreGoogleAdsDashboardCard {
    var header: some View {
        StoreDashboardCardHeader(DashboardCard.CardType.googleAds.name,
                                 showsError: viewModel.shouldShowErrorState) {
            StoreDashboardCardOverflowMenu(isDisabled: viewModel.syncingData) {
                Button(Localization.hideCard, action: viewModel.dismissCard)
            }
        }
    }

    var noCampaignView: some View {
        StoreDashboardOutlinedContent {
            HStack(alignment: .top, spacing: StoreSpacing.s5) {
                googleLogo

                VStack(alignment: .leading, spacing: StoreSpacing.s3) {
                    Text(Localization.NoCampaign.title)
                        .storeTextStyle(.titleLarge.strong)
                    Text(Localization.NoCampaign.subtitle)
                        .storeTextStyle(.bodyLarge)
                }
                .foregroundStyle(.storeOnSurface)
            }
        }
    }

    var googleLogo: some View {
        Image(uiImage: .googleLogo)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: StoreSize.iconContainerSize,
                   height: StoreSize.iconContainerSize)
            .accessibilityHidden(true)
    }

    var errorState: some View {
        StoreDashboardCardErrorView {
            ServiceLocator.analytics.track(event: .DynamicDashboard.cardRetryTapped(type: .googleAds))
            Task { await viewModel.reloadCard() }
        }
    }

    func statsView(with stats: GoogleAdsCampaignStatsTotals) -> some View {
        StoreDashboardOutlinedContent {
            HStack(alignment: .top, spacing: StoreSpacing.s5) {
                googleLogo

                VStack(alignment: .leading, spacing: StoreSpacing.s5) {
                    HStack {
                        Text(Localization.Stats.title)
                            .storeTextStyle(.bodyLarge.emphasized)

                        Spacer(minLength: StoreSpacing.s0)

                        StoreIcon.AngleRight.regular.image(size: .largeIncreased)
                            .flipsForRightToLeftLayoutDirection(true)
                            .accessibilityHidden(true)
                    }

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: StoreSpacing.s5) {
                            stat(Localization.Stats.impressions, value: stats.impressions ?? 0)
                            stat(Localization.Stats.clicks, value: stats.clicks ?? 0)
                        }
                        VStack(alignment: .leading, spacing: StoreSpacing.s5) {
                            stat(Localization.Stats.impressions, value: stats.impressions ?? 0)
                            stat(Localization.Stats.clicks, value: stats.clicks ?? 0)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .foregroundStyle(.storeOnSurface)
        }
    }

    func stat(_ title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: StoreSpacing.s3) {
            Text(title)
                .storeTextStyle(.bodyMedium)
            Text(value, format: .number)
                .storeTextStyle(.titleLarge.emphasized)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension StoreGoogleAdsDashboardCard {
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
    StoreGoogleAdsDashboardCard(viewModel: GoogleAdsDashboardCardViewModel(siteID: 135),
                           onCreateNewCampaign: {},
                           onShowAllCampaigns: {})
}
