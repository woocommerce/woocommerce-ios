import SwiftUI

/// Card to display a Google Ads Campaign stat and a list of campaigns for that stat on the Analytics Hub
///
struct GoogleAdsCampaignReportCard: View {
    /// Whether the web report is displayed.
    @State private var showingWebReport: Bool = false

    /// View model to drive the view content.
    @ObservedObject var viewModel: GoogleAdsCampaignReportCardViewModel

    /// Closure to perform when new Google Ads campaign is created.
    let onCreateNewCampaign: () -> Void

    var body: some View {
        if viewModel.showCampaignCTA {
            AnalyticsCTACard(title: Localization.title,
                             message: Localization.CallToAction.message,
                             buttonLabel: Localization.CallToAction.button,
                             isLoading: .constant(false), // No loading indicator needed
                             buttonAction: onCreateNewCampaign)
            .onAppear(perform: {
                viewModel.onDisplayCallToAction()
            })
        } else {
            VStack(alignment: .leading) {

                Text(Localization.title)
                    .foregroundColor(Color(.text))
                    .footnoteStyle()

                StatSelectionBar(allStats: viewModel.allStats,
                                 titleKeyPath: \.displayName,
                                 onSelection: viewModel.onSelection,
                                 selectedStat: $viewModel.selectedStat)
                    .padding(.top, Layout.titleSpacing)
                    .padding(.bottom, Layout.columnSpacing)

                HStack {
                    Text(viewModel.statValue)
                        .titleStyle()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .redacted(reason: viewModel.isRedacted ? .placeholder : [])
                        .shimmering(active: viewModel.isRedacted)

                    DeltaTag(value: viewModel.deltaValue,
                             backgroundColor: viewModel.deltaBackgroundColor,
                             textColor: viewModel.deltaTextColor)
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
                                             comment: "This text appears as the title of a card component on the analytics hub screen that displays Google Ads campaign performance data and statistics. The title is displayed in uppercase and helps users identify the Google Campaigns analytics section within the dashboard.").localizedUppercase
        static let campaignsTitle = NSLocalizedString("analyticsHub.googleCampaigns.campaignsList.title",
                                                      value: "Campaigns",
                                                      comment: "This text appears as a section title for the list of campaigns within the Google Ads campaign analytics card on the Analytics Hub screen. It serves as a header to identify the campaigns data section below it.")
        static let errorMessage = NSLocalizedString("analyticsHub.googleCampaigns.noCampaignStats",
                                                    value: "Unable to load Google campaigns analytics",
                                                    comment: "Error message displayed on the Google Campaigns analytics card when the app fails to load campaign statistics data from Google Ads.")

        enum CallToAction {
            static let message = NSLocalizedString("analyticsHub.googleCampaignsCTA.message",
                                                   value: "Drive sales and generate more traffic with Google Ads.",
                                                   comment: "This message appears on the Analytics Hub screen when there are no Google Ads campaign analytics to display, encouraging users to create paid campaigns to drive sales and traffic.")
            static let button = NSLocalizedString("analyticsHub.googleCampaignCTA.button",
                                                  value: "Add paid campaign",
                                                  comment: "This is a button label that appears in the Google Campaigns analytics card on the Analytics Hub screen when no campaign data is available. The button allows users to create a new Google Ads paid campaign to drive sales and traffic.")
        }
    }
}


// MARK: Previews
struct GoogleAdsCampaignReportCardPreviews: PreviewProvider {
    static var previews: some View {
        let viewModel = GoogleAdsCampaignReportCardViewModel(siteID: 123,
                                                             timeRange: .today,
                                                             usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter())
        GoogleAdsCampaignReportCard(viewModel: viewModel, onCreateNewCampaign: {})
            .addingTopAndBottomDividers()
            .previewLayout(.sizeThatFits)
    }
}
