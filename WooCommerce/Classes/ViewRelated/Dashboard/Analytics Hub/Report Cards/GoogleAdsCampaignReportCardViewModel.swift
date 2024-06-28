import Foundation
import Yosemite

/// Analytics Hub Google Ads Campaign Card ViewModel.
/// Used to transmit Google Ads campaigns analytics data.
///
final class GoogleAdsCampaignReportCardViewModel {
    /// Campaign stats for the current period
    ///
    private var currentPeriodStats: GoogleAdsCampaignStats?

    /// Campaign stats for the previous period
    ///
    private var previousPeriodStats: GoogleAdsCampaignStats?

    /// Selected time range
    ///
    private var timeRange: AnalyticsHubTimeRangeSelection.SelectionType

    /// Analytics Usage Tracks Event Emitter
    ///
    private let usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter

    /// Store admin URL
    ///
    private let storeAdminURL: String?

    /// Indicates if the values should be hidden (for loading state)
    ///
    var isRedacted: Bool

    init(currentPeriodStats: GoogleAdsCampaignStats?,
         previousPeriodStats: GoogleAdsCampaignStats?,
         timeRange: AnalyticsHubTimeRangeSelection.SelectionType,
         isRedacted: Bool = false,
         usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter,
         storeAdminURL: String? = ServiceLocator.stores.sessionManager.defaultSite?.adminURL) {
        self.currentPeriodStats = currentPeriodStats
        self.previousPeriodStats = previousPeriodStats
        self.timeRange = timeRange
        self.isRedacted = isRedacted
        self.usageTracksEventEmitter = usageTracksEventEmitter
        self.storeAdminURL = storeAdminURL
    }
}

extension GoogleAdsCampaignReportCardViewModel {

    /// Card Title
    ///
    var title: String {
        Localization.title
    }

    // MARK: Total Sales

    /// Total Sales title
    ///
    var totalSalesTitle: String {
        return Localization.totalSales
    }

    /// Total Sales value
    ///
    var totalSales: String {
        guard !isRedacted else {
            return "1000"
        }
        return StatsDataTextFormatter.formatAmount(currentPeriodStats?.totals.sales)
    }

    /// Total Sales delta percentage
    ///
    var delta: DeltaPercentage {
        isRedacted ? DeltaPercentage(string: "0%", direction: .zero)
        : StatsDataTextFormatter.createDeltaPercentage(from: previousPeriodStats?.totals.sales, to: currentPeriodStats?.totals.sales)
    }

    // MARK: Campaigns report

    /// Campaigns data to render.
    ///
    var campaignsData: [TopPerformersRow.Data] {
        isRedacted ? [.init(showImage: false, name: "Campaign", details: "Spend: $100", value: "$500")] : campaignRows(from: currentPeriodStats)
    }

    /// Indicates if there was an error loading campaigns part of the card.
    ///
    var showCampaignsError: Bool {
        isRedacted ? false : currentPeriodStats == nil
    }

    /// Error message if there was an error loading campaigns part of the card.
    ///
    var campaignsErrorMessage: String {
        Localization.noCampaignStats
    }

    /// View model for the web analytics report link
    ///
    var reportViewModel: AnalyticsReportLinkViewModel? {
        guard let url = AnalyticsWebReport.getUrl(for: .googlePrograms, timeRange: timeRange, storeAdminURL: storeAdminURL) else {
            return nil
        }
        return AnalyticsReportLinkViewModel(reportType: .googlePrograms,
                                            period: timeRange,
                                            webViewTitle: Localization.reportTitle,
                                            reportURL: url,
                                            usageTracksEventEmitter: usageTracksEventEmitter)
    }

    /// Helper functions to create `TopPerformersRow.Data` items from the provided `GoogleAdsCampaignStats`.
    ///
    private func campaignRows(from stats: GoogleAdsCampaignStats?) -> [TopPerformersRow.Data] {
        // Sort campaigns by their total sales.
        guard let sortedCampaigns = stats?.campaigns.sorted(by: { $0.subtotals.sales ?? 0 > $1.subtotals.sales ?? 0 }) else {
            return []
        }

        // Extract top five campaigns for display.
        let topCampaigns = Array(sortedCampaigns.prefix(5))

        return topCampaigns.map { campaign in
            return TopPerformersRow.Data(showImage: false,
                                         name: campaign.campaignName ?? "",
                                         details: Localization.spend(value: StatsDataTextFormatter.formatAmount(campaign.subtotals.spend)),
                                         value: StatsDataTextFormatter.formatAmount(campaign.subtotals.sales))
        }
    }
}

/// Convenience extension to create an `AnalyticsItemsSoldCard` from a view model.
///
extension AnalyticsTopPerformersCard {
    init(campaignsViewModel: GoogleAdsCampaignReportCardViewModel) {
        // Header with selected metric stats
        self.title = campaignsViewModel.title
        self.statTitle = campaignsViewModel.totalSalesTitle
        self.statValue = campaignsViewModel.totalSales
        self.delta = campaignsViewModel.delta.string
        self.deltaBackgroundColor = campaignsViewModel.delta.direction.deltaBackgroundColor
        self.deltaTextColor = campaignsViewModel.delta.direction.deltaTextColor
        self.isStatsRedacted = campaignsViewModel.isRedacted
        // This card gets its metrics and campaigns list from the same source.
        // If there is a problem loading stats data, the error message only appears once at the bottom of the card.
        self.showStatsError = false
        self.statsErrorMessage = ""
        self.reportViewModel = campaignsViewModel.reportViewModel

        // Top performers (campaigns) list
        self.topPerformersData = campaignsViewModel.campaignsData
        self.isTopPerformersRedacted = campaignsViewModel.isRedacted
        self.showTopPerformersError = campaignsViewModel.showCampaignsError
        self.topPerformersErrorMessage = campaignsViewModel.campaignsErrorMessage
    }
}

// MARK: Constants
private extension GoogleAdsCampaignReportCardViewModel {
    enum Localization {
        static let reportTitle = NSLocalizedString("analyticsHub.googleCampaigns.reportTitle",
                                                   value: "Programs Report",
                                                   comment: "Title for the Google Programs report linked in the Analytics Hub")
        static let title = NSLocalizedString("analyticsHub.googleCampaigns.title",
                                             value: "Google Campaigns",
                                             comment: "Title for the Google campaigns card on the analytics hub screen.").localizedUppercase
        static let totalSales = NSLocalizedString("analyticsHub.googleCampaigns.totalSalesTitle",
                                                  value: "Total Sales",
                                                  comment: "Title for the Total Sales column on the Google Ads campaigns card on the analytics hub screen.")
        static let noCampaignStats = NSLocalizedString("analyticsHub.googleCampaigns.noCampaignStats",
                                                       value: "Unable to load Google campaigns analytics",
                                                       comment: "Text displayed when there is an error loading Google Ads campaigns stats data.")
        static func spend(value: String) -> String {
            String.localizedStringWithFormat(NSLocalizedString("analyticsHub.googleCampaigns.spendSubtitle",
                                                               value: "Spend: %@",
                                                               comment: "Label for the total spend amount on a Google Ads campaign in the Analytics Hub."
                                                               + "The placeholder is a formatted monetary amount, e.g. Spend: $123."),
                                             value)
        }
    }
}
