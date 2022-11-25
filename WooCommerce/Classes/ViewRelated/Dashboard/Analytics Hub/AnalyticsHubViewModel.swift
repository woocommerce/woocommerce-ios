import Foundation
import Yosemite
import class UIKit.UIColor

/// Main View Model for the Analytics Hub.
///
final class AnalyticsHubViewModel: ObservableObject {

    private let siteID: Int64
    private let stores: StoresManager
    private let timeRangeGenerator: AnalyticsHubTimeRangeGenerator

    init(siteID: Int64,
         statsTimeRange: StatsTimeRangeV4,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
        self.timeRangeGenerator = AnalyticsHubTimeRangeGenerator(selectedTimeRange: statsTimeRange)
        self.timeRangeCard = AnalyticsTimeRangeCardViewModel(selectedRangeTitle: timeRangeGenerator.selectionDescription,
                                                             currentRangeSubtitle: timeRangeGenerator.currentRangeDescription,
                                                             previousRangeSubtitle: timeRangeGenerator.previousRangeDescription)

        Task.init {
            do {
                try await retrieveOrderStats()
            } catch {
                DDLogWarn("⚠️ Error fetching analytics data: \(error)")
            }
        }
    }

    /// Revenue Card ViewModel
    ///
    @Published var revenueCard = AnalyticsReportCardViewModel(title: Localization.RevenueCard.title,
                                                              leadingTitle: Localization.RevenueCard.leadingTitle,
                                                              leadingValue: Constants.placeholderValue,
                                                              leadingDelta: Constants.placeholderDelta.string,
                                                              leadingDeltaColor: Constants.deltaColor(for: Constants.placeholderDelta.direction),
                                                              trailingTitle: Localization.RevenueCard.trailingTitle,
                                                              trailingValue: Constants.placeholderValue,
                                                              trailingDelta: Constants.placeholderDelta.string,
                                                              trailingDeltaColor: Constants.deltaColor(for: Constants.placeholderDelta.direction))

    /// Orders Card ViewModel
    ///
    @Published var ordersCard = AnalyticsReportCardViewModel(title: Localization.OrderCard.title,
                                                             leadingTitle: Localization.OrderCard.leadingTitle,
                                                             leadingValue: Constants.placeholderValue,
                                                             leadingDelta: Constants.placeholderDelta.string,
                                                             leadingDeltaColor: Constants.deltaColor(for: Constants.placeholderDelta.direction),
                                                             trailingTitle: Localization.OrderCard.trailingTitle,
                                                             trailingValue: Constants.placeholderValue,
                                                             trailingDelta: Constants.placeholderDelta.string,
                                                             trailingDeltaColor: Constants.deltaColor(for: Constants.placeholderDelta.direction))

    /// Time Range ViewModel
    ///
    @Published var timeRangeCard: AnalyticsTimeRangeCardViewModel

    // MARK: Private data

    /// Order stats for the current selected time period
    ///
    @Published private var currentOrderStats: OrderStatsV4? = nil

    /// Order stats for the previous time period (for comparison)
    ///
    @Published private var previousOrderStats: OrderStatsV4? = nil
}

private extension AnalyticsHubViewModel {

    @MainActor
    func retrieveOrderStats() async throws {
        let currentTimeRange = try timeRangeGenerator.currentTimeRange
        let previousTimeRange = try timeRangeGenerator.previousTimeRange

        async let currentPeriodRequest = retrieveStats(earliestDateToInclude: currentTimeRange.start,
                                                       latestDateToInclude: currentTimeRange.end,
                                                       forceRefresh: true)
        async let previousPeriodRequest = retrieveStats(earliestDateToInclude: previousTimeRange.start,
                                                        latestDateToInclude: previousTimeRange.end,
                                                        forceRefresh: true)
        let (currentPeriodStats, previousPeriodStats) = try await (currentPeriodRequest, previousPeriodRequest)
        self.currentOrderStats = currentPeriodStats
        self.previousOrderStats = previousPeriodStats
    }

    @MainActor
    func retrieveStats(earliestDateToInclude: Date,
                       latestDateToInclude: Date,
                       forceRefresh: Bool) async throws -> OrderStatsV4 {
        try await withCheckedThrowingContinuation { continuation in
            // TODO: get unit and quantity from the selected period
            let unit: StatsGranularityV4 = .daily
            let quantity = 31

            let action = StatsActionV4.retrieveCustomStats(siteID: siteID,
                                                           unit: unit,
                                                           earliestDateToInclude: earliestDateToInclude,
                                                           latestDateToInclude: latestDateToInclude,
                                                           quantity: quantity,
                                                           forceRefresh: forceRefresh) { result in
                continuation.resume(with: result)
            }
            stores.dispatch(action)
        }
    }
}

// MARK: - Constants
private extension AnalyticsHubViewModel {
    enum Constants {
        static let placeholderValue = "-"
        static let placeholderDelta = StatsDataTextFormatter.createDeltaPercentage(from: 0.0, to: 0.0)
        static func deltaColor(for direction: StatsDataTextFormatter.DeltaPercentage.Direction) -> UIColor {
            switch direction {
            case .positive:
                return .withColorStudio(.green, shade: .shade50)
            case .negative, .zero:
                return .withColorStudio(.red, shade: .shade40)
            }
        }
    }

    enum Localization {
        enum RevenueCard {
            static let title = NSLocalizedString("REVENUE", comment: "Title for revenue analytics section in the Analytics Hub")
            static let leadingTitle = NSLocalizedString("Total Sales", comment: "Label for total sales (gross revenue) in the Analytics Hub")
            static let trailingTitle = NSLocalizedString("Net Sales", comment: "Label for net sales (net revenue) in the Analytics Hub")
        }

        enum OrderCard {
            static let title = NSLocalizedString("ORDERS", comment: "Title for order analytics section in the Analytics Hub")
            static let leadingTitle = NSLocalizedString("Total Orders", comment: "Label for total number of orders in the Analytics Hub")
            static let trailingTitle = NSLocalizedString("Average Order Value", comment: "Label for average value of orders in the Analytics Hub")
        }
    }
}
