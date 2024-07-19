import Foundation
import Yosemite
import protocol WooFoundation.Analytics

/// Analytics Hub Google Ads Campaign Card ViewModel.
/// Used to transmit Google Ads campaigns analytics data.
///
final class GoogleAdsCampaignReportCardViewModel: ObservableObject {
    private let analytics: Analytics

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

    /// All available stats for Google Ads campaigns.
    ///
    let allStats = GoogleAdsCampaignStatsTotals.TotalData.allCases

    /// The currently selected stat to display. Defaults to total sales.
    ///
    @Published var selectedStat: GoogleAdsCampaignStatsTotals.TotalData = .sales

    init(currentPeriodStats: GoogleAdsCampaignStats?,
         previousPeriodStats: GoogleAdsCampaignStats?,
         timeRange: AnalyticsHubTimeRangeSelection.SelectionType,
         isRedacted: Bool = false,
         usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter,
         storeAdminURL: String? = ServiceLocator.stores.sessionManager.defaultSite?.adminURL,
         analytics: Analytics = ServiceLocator.analytics) {
        self.currentPeriodStats = currentPeriodStats
        self.previousPeriodStats = previousPeriodStats
        self.timeRange = timeRange
        self.isRedacted = isRedacted
        self.usageTracksEventEmitter = usageTracksEventEmitter
        self.storeAdminURL = storeAdminURL
        self.analytics = analytics
    }

    /// Closure to perform when a new stat is selected on the Google Campaigns card.
    ///
    func onSelection(_ stat: GoogleAdsCampaignStatsTotals.TotalData) {
        usageTracksEventEmitter.interacted()
        analytics.track(event: .AnalyticsHub.selectedMetric(stat.tracksIdentifier, for: .googleCampaigns))
    }
}

extension GoogleAdsCampaignReportCardViewModel {

    // MARK: Selected Stat (Total)

    /// Value for the selected stat
    ///
    var statValue: String {
        guard !isRedacted else {
            return "1000"
        }
        return StatsDataTextFormatter.createGoogleCampaignsStatText(for: selectedStat, from: currentPeriodStats)
    }

    /// Delta percentage for the selected stat
    ///
    private var delta: DeltaPercentage {
        isRedacted ? DeltaPercentage(string: "0%", direction: .zero)
        : StatsDataTextFormatter.createDeltaPercentage(from: previousPeriodStats?.totals.getDoubleValue(for: selectedStat),
                                                       to: currentPeriodStats?.totals.getDoubleValue(for: selectedStat))
    }

    /// Delta text for the selected stat
    ///
    var deltaValue: String {
        delta.string
    }

    /// Delta text color for the selected stat
    ///
    var deltaTextColor: UIColor {
        delta.direction.deltaTextColor
    }

    /// Delta background color for the selected stat
    ///
    var deltaBackgroundColor: UIColor {
        delta.direction.deltaBackgroundColor
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
        // Sort campaigns by the selected stat.
        guard let sortedCampaigns = stats?.campaigns.sorted(by: {
            $0.subtotals.getDoubleValue(for: selectedStat) > $1.subtotals.getDoubleValue(for: selectedStat)
        }) else {
            return []
        }

        // Extract top five campaigns for display.
        let topCampaigns = Array(sortedCampaigns.prefix(5))

        return topCampaigns.map { campaign in
            // Show campaign spend in row details, unless spend is the selected stat.
            let detailsText = {
                guard selectedStat != .spend else {
                    return Localization.sales(value: StatsDataTextFormatter.createGoogleCampaignsSubtotalText(for: .sales, from: campaign))
                }
                return Localization.spend(value: StatsDataTextFormatter.createGoogleCampaignsSubtotalText(for: .spend, from: campaign))
            }()

            return TopPerformersRow.Data(showImage: false,
                                         name: campaign.campaignName ?? "",
                                         details: detailsText,
                                         value: StatsDataTextFormatter.createGoogleCampaignsSubtotalText(for: selectedStat, from: campaign))
        }
    }
}

// MARK: Google Ads Campaign Creation
extension GoogleAdsCampaignReportCardViewModel {
    /// Whether to show the call to action to create a new campaign.
    ///
    var showCampaignCTA: Bool {
        false // TODO-13368: Add logic for when to show the call to action
    }

    /// Whether there are paid campaigns to display.
    ///
    var hasPaidCampaigns: Bool {
        campaignsData.isNotEmpty
    }
}

// MARK: Constants
private extension GoogleAdsCampaignReportCardViewModel {
    enum Localization {
        static let reportTitle = NSLocalizedString("analyticsHub.googleCampaigns.reportTitle",
                                                   value: "Programs Report",
                                                   comment: "Title for the Google Programs report linked in the Analytics Hub")
        static func spend(value: String) -> String {
            String.localizedStringWithFormat(NSLocalizedString("analyticsHub.googleCampaigns.spendSubtitle",
                                                               value: "Spend: %@",
                                                               comment: "Label for the total spend amount on a Google Ads campaign in the Analytics Hub."
                                                               + "The placeholder is a formatted monetary amount, e.g. Spend: $123."),
                                             value)
        }
        static func sales(value: String) -> String {
            String.localizedStringWithFormat(NSLocalizedString("analyticsHub.googleCampaigns.salesSubtitle",
                                                               value: "Sales: %@",
                                                               comment: "Label for the total sales amount on a Google Ads campaign in the Analytics Hub."
                                                               + "The placeholder is a formatted monetary amount, e.g. Sales: $123."),
                                             value)
        }
    }
}

// MARK: - Methods for rendering a SwiftUI Preview
extension GoogleAdsCampaignReportCardViewModel {
    static func sampleStats() -> GoogleAdsCampaignStats {
        GoogleAdsCampaignStats(siteID: 1234,
                               totals: GoogleAdsCampaignStatsTotals(sales: 2234, spend: 225, clicks: 2345, impressions: 23456, conversions: 1032),
                               campaigns: [GoogleAdsCampaignStatsItem(campaignID: 1,
                                                                      campaignName: "Spring Sale Campaign",
                                                                      rawStatus: "enabled",
                                                                      subtotals: GoogleAdsCampaignStatsTotals(sales: 1232,
                                                                                                              spend: 100,
                                                                                                              clicks: 1000,
                                                                                                              impressions: 10000,
                                                                                                              conversions: 300)),
                                           GoogleAdsCampaignStatsItem(campaignID: 2,
                                                                      campaignName: "Summer Campaign",
                                                                      rawStatus: "enabled",
                                                                      subtotals: GoogleAdsCampaignStatsTotals(sales: 800,
                                                                                                              spend: 50,
                                                                                                              clicks: 900,
                                                                                                              impressions: 5000,
                                                                                                              conversions: 400)),
                                           GoogleAdsCampaignStatsItem(campaignID: 3,
                                                                      campaignName: "Winter Campaign",
                                                                      rawStatus: "enabled",
                                                                      subtotals: GoogleAdsCampaignStatsTotals(sales: 750,
                                                                                                              spend: 50,
                                                                                                              clicks: 800,
                                                                                                              impressions: 4000,
                                                                                                              conversions: 200)),
                                           GoogleAdsCampaignStatsItem(campaignID: 4,
                                                                      campaignName: "New Year Campaign",
                                                                      rawStatus: "enabled",
                                                                      subtotals: GoogleAdsCampaignStatsTotals(sales: 200,
                                                                                                              spend: 25,
                                                                                                              clicks: 300,
                                                                                                              impressions: 1000,
                                                                                                              conversions: 50))],
                               nextPageToken: nil)
    }
}
