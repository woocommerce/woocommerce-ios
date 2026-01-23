import Foundation
import Yosemite

final class GiftCardsReportCardViewModel: AnalyticsReportCardProtocol {
    /// Gift card stats for the current period
    ///
    private var currentPeriodStats: GiftCardStats?

    /// Gift card stats for the previous period
    ///
    private var previousPeriodStats: GiftCardStats?

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

    init(currentPeriodStats: GiftCardStats?,
         previousPeriodStats: GiftCardStats?,
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

// MARK: AnalyticsReportCardProtocol conformance

extension GiftCardsReportCardViewModel {

    var title: String {
        Localization.title
    }

    // MARK: Used metric

    var leadingTitle: String {
        Localization.leadingTitle
    }

    var leadingValue: String {
        isRedacted ? "100" : StatsDataTextFormatter.createGiftCardsUsedText(giftCardStats: currentPeriodStats)
    }

    var leadingDelta: DeltaPercentage? {
        isRedacted ? DeltaPercentage(string: "0%", direction: .zero)
        : StatsDataTextFormatter.createDelta(for: .giftCardsCount, from: previousPeriodStats, to: currentPeriodStats)
    }

    var leadingChartData: [Double] {
        isRedacted ? [] : StatsIntervalDataParser.getChartData(for: .giftCardsCount, from: currentPeriodStats)
    }

    // MARK: Net Amount metric

    var trailingTitle: String {
        Localization.trailingTitle
    }

    var trailingValue: String {
        isRedacted ? "$1000" : StatsDataTextFormatter.createGiftCardsNetAmountText(giftCardStats: currentPeriodStats)
    }

    var trailingDelta: DeltaPercentage? {
        isRedacted ? DeltaPercentage(string: "0%", direction: .zero)
        : StatsDataTextFormatter.createDelta(for: .netAmount, from: previousPeriodStats, to: currentPeriodStats)
    }

    var trailingChartData: [Double] {
        isRedacted ? [] : StatsIntervalDataParser.getChartData(for: .netAmount, from: currentPeriodStats)
    }

    var showSyncError: Bool {
        isRedacted ? false : currentPeriodStats == nil || previousPeriodStats == nil
    }

    var syncErrorMessage: String {
        Localization.noGiftCards
    }

    var reportViewModel: AnalyticsReportLinkViewModel? {
        guard let url = AnalyticsWebReport.getUrl(for: .giftCards, timeRange: timeRange, storeAdminURL: storeAdminURL) else {
            return nil
        }
        return AnalyticsReportLinkViewModel(reportType: .giftCards,
                                            period: timeRange,
                                            webViewTitle: Localization.reportTitle,
                                            reportURL: url,
                                            usageTracksEventEmitter: usageTracksEventEmitter)
    }
}

// MARK: Constants
private extension GiftCardsReportCardViewModel {
    enum Localization {
        static let title = NSLocalizedString("analyticsHub.giftCardsCard.title",
                                             value: "GIFT CARDS",
                                             comment: "This text appears as the main title/heading for the Gift Cards analytics section within the Analytics Hub dashboard, identifying the specific report card that displays gift card usage statistics and metrics.")
        static let leadingTitle = NSLocalizedString("analyticsHub.giftCardsCard.leadingTitle",
                                                    value: "Used",
                                                    comment: "This text appears as a label in the Analytics Hub's Gift Cards report card, indicating the number of gift cards that have been used by customers during the selected time period.")
        static let trailingTitle = NSLocalizedString("analyticsHub.giftCardsCard.trailingTitle",
                                                     value: "Net Amount",
                                                     comment: "This text appears as a label in the Analytics Hub's Gift Cards report card, specifically labeling the metric that shows the net monetary amount from gift card usage.")
        static let noGiftCards = NSLocalizedString("analyticsHub.giftCardsCard.syncErrorMessage",
                                                   value: "Unable to load gift card analytics",
                                                   comment: "Error message displayed in the gift cards analytics card on the Analytics Hub screen when the app fails to load gift card statistics data.")
        static let reportTitle = NSLocalizedString("analyticsHub.giftCardsCard.reportTitle",
                                                   value: "Gift Cards Report",
                                                   comment: "This text appears as the title of a detailed gift cards analytics report that users can access from the Analytics Hub dashboard in a WooCommerce mobile app.")
    }
}
