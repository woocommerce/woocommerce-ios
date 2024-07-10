import SwiftUI

/// Card to display a Google Ads Campaign stat and a list of campaigns for that stat on the Analytics Hub
///
struct GoogleAdsCampaignReportCard: View {
    /// Whether the web report is displayed.
    @State private var showingWebReport: Bool = false

    /// View model to drive the view content.
    @StateObject var viewModel: GoogleAdsCampaignReportCardViewModel

    var body: some View {
        VStack(alignment: .leading) {

            Text(Localization.title)
                .foregroundColor(Color(.text))
                .footnoteStyle()

            StatSelectionBar(allStats: viewModel.allStats, titleKeyPath: \.displayName, onSelection: nil, selectedStat: $viewModel.selectedStat)
                .padding(.top, Layout.titleSpacing)
                .padding(.bottom, Layout.columnSpacing)

            HStack {
                Text(viewModel.totalSales)
                    .titleStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .redacted(reason: viewModel.isRedacted ? .placeholder : [])
                    .shimmering(active: viewModel.isRedacted)

                DeltaTag(value: viewModel.delta.string,
                         backgroundColor: viewModel.delta.direction.deltaBackgroundColor,
                         textColor: viewModel.delta.direction.deltaTextColor)
                    .redacted(reason: viewModel.isRedacted ? .placeholder : [])
                    .shimmering(active: viewModel.isRedacted)
            }

            TopPerformersView(itemTitle: Localization.campaignsTitle.localizedCapitalized,
                              valueTitle: viewModel.selectedStat.displayName,
                              rows: viewModel.campaignsData,
                              isRedacted: viewModel.isRedacted)
                .padding(.vertical, Layout.columnSpacing)
                .renderedIf(!viewModel.showCampaignsError)

            if viewModel.showCampaignsError {
                Text(Localization.errorMessage)
                    .foregroundColor(Color(.text))
                    .subheadlineStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, Layout.columnSpacing)
            }

            if let reportViewModel = viewModel.reportViewModel {
                AnalyticsReportLink(showingWebReport: $showingWebReport, reportViewModel: reportViewModel)
            }
        }
        .padding(Layout.cardPadding)
    }
}

// MARK: Constants
private extension GoogleAdsCampaignReportCard {
    enum Layout {
        static let titleSpacing: CGFloat = 24
        static let cardPadding: CGFloat = 16
        static let columnSpacing: CGFloat = 10
    }

    enum Localization {
        static let title = NSLocalizedString("analyticsHub.googleCampaigns.title",
                                             value: "Google Campaigns",
                                             comment: "Title for the Google campaigns card on the analytics hub screen.").localizedUppercase
        static let campaignsTitle = NSLocalizedString("analyticsHub.googleCampaigns.campaignsList.title",
                                                      value: "Campaigns",
                                                      comment: "Title for the list of campaigns on the Google campaigns card on the analytics hub screen.")
        static let errorMessage = NSLocalizedString("analyticsHub.googleCampaigns.noCampaignStats",
                                                    value: "Unable to load Google campaigns analytics",
                                                    comment: "Text displayed when there is an error loading Google Ads campaigns stats data.")
    }
}


// MARK: Previews
struct GoogleAdsCampaignReportCardPreviews: PreviewProvider {
    static var previews: some View {
        let viewModel = GoogleAdsCampaignReportCardViewModel(currentPeriodStats: GoogleAdsCampaignReportCardViewModel.sampleStats(),
                                                             previousPeriodStats: GoogleAdsCampaignReportCardViewModel.sampleStats(),
                                                             timeRange: .today,
                                                             usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter(),
                                                             storeAdminURL: "https://woocommerce.com")
        GoogleAdsCampaignReportCard(viewModel: viewModel)
            .addingTopAndBottomDividers()
            .previewLayout(.sizeThatFits)

        let emptyViewModel = GoogleAdsCampaignReportCardViewModel(currentPeriodStats: nil,
                                                                  previousPeriodStats: nil,
                                                                  timeRange: .today,
                                                                  usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter(),
                                                                  storeAdminURL: "https://woocommerce.com")
        GoogleAdsCampaignReportCard(viewModel: emptyViewModel)
            .addingTopAndBottomDividers()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("No data")
    }
}
