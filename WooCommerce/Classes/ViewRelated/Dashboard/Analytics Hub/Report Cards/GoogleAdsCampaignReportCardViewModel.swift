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

    /// Google Ads campaign creation eligibility checker. Optimistically defaults to `true`, to show loading view while checking eligibility.
    ///
    private let googleAdsEligibilityChecker: GoogleAdsEligibilityChecker

    /// Whether the store is eligible for Google Ads campaign creation. Optimistically defaults to `true`, to show loading view while checking eligibility.
    ///
    @Published private(set) var isEligibleForGoogleAds: Bool = true

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

    // MARK: Stats Properties

    /// The currently selected stat to display. Defaults to total sales.
    ///
    @Published var selectedStat: GoogleAdsCampaignStatsTotals.TotalData = .sales

    /// Value for the selected stat.
    ///
    @Published private(set) var statValue: String = StatsDataTextFormatter.createGoogleCampaignsStatText(for: .sales, from: nil)

    /// Delta percentage for the selected stat.
    ///
    @Published private var delta: DeltaPercentage = StatsDataTextFormatter.createDeltaPercentage(from: Optional<Decimal>.none, to: Optional<Decimal>.none)

    /// Campaigns data to render.
    ///
    @Published private(set) var campaignsData: [TopPerformersRow.Data] = []

    /// View model for the web analytics report link
    ///
    private(set) lazy var reportViewModel: AnalyticsReportLinkViewModel? = {
        guard let url = AnalyticsWebReport.getUrl(for: .googlePrograms, timeRange: timeRangeSelectionType, storeAdminURL: storeAdminURL) else {
            return nil
        }
        return AnalyticsReportLinkViewModel(reportType: .googlePrograms,
                                            period: timeRangeSelectionType,
                                            webViewTitle: Localization.reportTitle,
                                            reportURL: url,
                                            usageTracksEventEmitter: usageTracksEventEmitter)
    }()

    /// Indicates if there was an error loading campaigns part of the card.
    ///
    var showCampaignsError: Bool {
        isRedacted ? false : currentPeriodStats == nil
    }

    /// Whether to show the call to action to create a new campaign.
    ///
    var showCampaignCTA: Bool {
        guard !isRedacted, !showCampaignsError else {
            return false
        }
        return isEligibleForGoogleAds && campaignsData.isEmpty && !didCreateCampaign
    }

    /// Whether a paid campaign has been created via the call to action.
    ///
    /// This can be set to `true` to prevent the call to action from being persistently displayed, even if there are no campaign analytics yet.
    ///
    @Published private var didCreateCampaign: Bool = false

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

        bindStatsPropertiesWithData()
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

// MARK: Card Data
extension GoogleAdsCampaignReportCardViewModel {
    /// Binds stats properties to render on card with stats data.
    ///
    private func bindStatsPropertiesWithData() {
        $currentPeriodStats.combineLatest($selectedStat, $isRedacted)
            .map { currentPeriodStats, selectedStat, isRedacted in
                guard !isRedacted else {
                    return "1000"
                }
                return StatsDataTextFormatter.createGoogleCampaignsStatText(for: selectedStat, from: currentPeriodStats)
            }
            .assign(to: &$statValue)

        $currentPeriodStats.combineLatest($previousPeriodStats, $selectedStat, $isRedacted)
            .map { currentPeriodStats, previousPeriodStats, selectedStat, isRedacted in
                guard !isRedacted else {
                    return DeltaPercentage(string: "0%", direction: .zero)
                }
                return StatsDataTextFormatter.createDeltaPercentage(from: previousPeriodStats?.totals.getDoubleValue(for: selectedStat),
                                                                    to: currentPeriodStats?.totals.getDoubleValue(for: selectedStat))
            }
            .assign(to: &$delta)

        $currentPeriodStats.combineLatest($selectedStat, $isRedacted)
            .map { [weak self] currentPeriodStats, selectedStat, isRedacted in
                guard let self, !isRedacted else {
                    return [.init(showImage: false, name: "Campaign", details: "Spend: $100", value: "$500")]
                }
                return campaignRows(from: currentPeriodStats, for: selectedStat)
            }
            .assign(to: &$campaignsData)
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

    /// Helper functions to create `TopPerformersRow.Data` items from the provided `GoogleAdsCampaignStats`.
    ///
    private func campaignRows(from stats: GoogleAdsCampaignStats?, for selectedStat: GoogleAdsCampaignStatsTotals.TotalData) -> [TopPerformersRow.Data] {
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
    /// Tracks when the call to action is displayed.
    ///
    func onDisplayCallToAction() {
        analytics.track(event: .GoogleAds.entryPointDisplayed(source: .analyticsHub))
    }

    /// Closure to be called when a campaign is successfully created from the call to action.
    ///
    @MainActor
    func onGoogleCampaignCreated() async {
        didCreateCampaign = true
        await reload()
    }

    /// Checks whether the store is eligible for campaign creation.
    ///
    @MainActor
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
