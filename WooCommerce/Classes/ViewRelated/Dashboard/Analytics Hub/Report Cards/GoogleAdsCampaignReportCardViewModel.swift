import Foundation
import Yosemite
import protocol WooFoundation.Analytics

/// Analytics Hub Google Ads Campaign Card ViewModel.
/// Used to transmit Google Ads campaigns analytics data.
///
final class GoogleAdsCampaignReportCardViewModel: ObservableObject {
    private let siteID: Int64
    private let stores: StoresManager
    private let analytics: Analytics

    /// Google Ads campaign creation eligibility checker
    ///
    private let googleAdsEligibilityChecker: GoogleAdsEligibilityChecker

    /// Whether the store is eligible for Google Ads campaign creation.
    ///
    @Published private(set) var isEligibleForGoogleAds: Bool = false

    /// Campaign stats for the current period
    ///
    @Published private var currentPeriodStats: GoogleAdsCampaignStats? = nil

    /// Campaign stats for the previous period
    ///
    @Published private var previousPeriodStats: GoogleAdsCampaignStats? = nil

    /// Selected time range
    ///
    private var timeRangeSelection: AnalyticsHubTimeRangeSelection

    /// Selected time range type
    ///
    private var timeRangeSelectionType: AnalyticsHubTimeRangeSelection.SelectionType

    /// Analytics Usage Tracks Event Emitter
    ///
    private let usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter

    /// Store admin URL
    ///
    private let storeAdminURL: String?

    /// Indicates if the values should be hidden (for loading state)
    ///
    @Published private(set) var isRedacted: Bool = false

    /// All available stats for Google Ads campaigns.
    ///
    let allStats = GoogleAdsCampaignStatsTotals.TotalData.allCases

    /// The currently selected stat to display. Defaults to total sales.
    ///
    @Published var selectedStat: GoogleAdsCampaignStatsTotals.TotalData = .sales

    init(siteID: Int64,
         timeRange: AnalyticsHubTimeRangeSelection.SelectionType,
         usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter,
         analytics: Analytics = ServiceLocator.analytics,
         stores: StoresManager = ServiceLocator.stores,
         googleAdsEligibilityChecker: GoogleAdsEligibilityChecker = DefaultGoogleAdsEligibilityChecker()) {
        self.siteID = siteID
        self.timeRangeSelectionType = timeRange
        self.timeRangeSelection = AnalyticsHubTimeRangeSelection(selectionType: timeRange, timezone: .siteTimezone)
        self.usageTracksEventEmitter = usageTracksEventEmitter
        self.storeAdminURL = stores.sessionManager.defaultSite?.adminURL
        self.analytics = analytics
        self.stores = stores
        self.googleAdsEligibilityChecker = googleAdsEligibilityChecker
    }

    /// Reloads the data for the card.
    ///
    func reload() async {
        do {
            let currentTimeRange = try timeRangeSelection.unwrapCurrentTimeRange()
            let previousTimeRange = try timeRangeSelection.unwrapPreviousTimeRange()
            await retrieveGoogleCampaignStats(currentTimeRange: currentTimeRange, previousTimeRange: previousTimeRange, timeZone: .siteTimezone)
        } catch {
            currentPeriodStats = nil
            previousPeriodStats = nil
            DDLogWarn("⚠️ Error fetching Google Ads Campaigns analytics data: \(error)")
        }
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
        guard let url = AnalyticsWebReport.getUrl(for: .googlePrograms, timeRange: timeRangeSelectionType, storeAdminURL: storeAdminURL) else {
            return nil
        }
        return AnalyticsReportLinkViewModel(reportType: .googlePrograms,
                                            period: timeRangeSelectionType,
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

    /// Tracks when the call to action is displayed.
    ///
    func onDisplayCallToAction() {
        analytics.track(event: .GoogleAds.entryPointDisplayed(source: .analyticsHub))
    }

    /// Checks whether the store is eligible for campaign creation.
    ///
    private func checkGoogleAdsEligibility() async -> Bool {
        isEligibleForGoogleAds = await googleAdsEligibilityChecker.isSiteEligible(siteID: siteID)
        return isEligibleForGoogleAds
    }
}

// MARK: Networking
private extension GoogleAdsCampaignReportCardViewModel {
    @MainActor
    func retrieveGoogleCampaignStats(currentTimeRange: AnalyticsHubTimeRange, previousTimeRange: AnalyticsHubTimeRange, timeZone: TimeZone) async {
        isRedacted = true
        defer {
            isRedacted = false
        }

        // Only retrieve stats if Google Ads is connected on the store.
        guard await checkGoogleAdsEligibility() else {
            return
        }

        async let currentPeriodRequest = retrieveGoogleCampaignStats(timeZone: timeZone,
                                                                     earliestDateToInclude: currentTimeRange.start,
                                                                     latestDateToInclude: currentTimeRange.end)
        async let previousPeriodRequest = retrieveGoogleCampaignStats(timeZone: timeZone,
                                                                      earliestDateToInclude: previousTimeRange.start,
                                                                      latestDateToInclude: previousTimeRange.end)

        let allStats: (currentPeriodStats: GoogleAdsCampaignStats, previousPeriodStats: GoogleAdsCampaignStats)?
        allStats = try? await (currentPeriodRequest, previousPeriodRequest)
        currentPeriodStats = allStats?.currentPeriodStats
        previousPeriodStats = allStats?.previousPeriodStats
    }

    @MainActor
    /// Retrieves Google campaign stats using the `retrieveGoogleCampaignStats` action.
    ///
    func retrieveGoogleCampaignStats(timeZone: TimeZone,
                                     earliestDateToInclude: Date,
                                     latestDateToInclude: Date) async throws -> GoogleAdsCampaignStats {
        try await withCheckedThrowingContinuation { continuation in
            let action = GoogleAdsAction.retrieveCampaignStats(siteID: siteID,
                                                               timeZone: timeZone,
                                                               earliestDateToInclude: earliestDateToInclude,
                                                               latestDateToInclude: latestDateToInclude) { result in
                continuation.resume(with: result)
            }
            stores.dispatch(action)
        }
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
