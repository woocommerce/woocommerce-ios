import Foundation
import Yosemite
import Combine
import class UIKit.UIColor

/// Main View Model for the Analytics Hub.
///
final class AnalyticsHubViewModel: ObservableObject {

    private let siteID: Int64
    private let stores: StoresManager
    private let timeRangeGenerator: AnalyticsHubTimeRangeGenerator

    private var subscriptions = Set<AnyCancellable>()

    init(siteID: Int64,
         statsTimeRange: StatsTimeRangeV4,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
        self.timeRangeGenerator = AnalyticsHubTimeRangeGenerator(selectedTimeRange: statsTimeRange)
        self.timeRangeCard = AnalyticsTimeRangeCardViewModel(selectedRangeTitle: timeRangeGenerator.selectionDescription,
                                                             currentRangeSubtitle: timeRangeGenerator.generateCurrentRangeDescription(),
                                                             previousRangeSubtitle: timeRangeGenerator.generatePreviousRangeDescription())

        bindViewModelsWithData()
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
    @Published var revenueCard = AnalyticsHubViewModel.revenueCard(currentPeriodStats: nil, previousPeriodStats: nil)

    /// Orders Card ViewModel
    ///
    @Published var ordersCard = AnalyticsHubViewModel.ordersCard(currentPeriodStats: nil, previousPeriodStats: nil)

    /// Time Range ViewModel
    ///
    @Published var timeRangeCard: AnalyticsTimeRangeCardViewModel

    /// Products Card ViewModel
    ///
    @Published var productCard = AnalyticsProductCardViewModel(itemsSold: "3,234",
                                                               delta: "+43%",
                                                               deltaBackgroundColor: .withColorStudio(.green, shade: .shade50))

    // MARK: Private data

    /// Order stats for the current selected time period
    ///
    @Published private var currentOrderStats: OrderStatsV4? = nil

    /// Order stats for the previous time period (for comparison)
    ///
    @Published private var previousOrderStats: OrderStatsV4? = nil
}

// MARK: Networking
private extension AnalyticsHubViewModel {

    @MainActor
    func retrieveOrderStats() async throws {
        let currentTimeRange = try timeRangeGenerator.unwrapCurrentTimeRange()
        let previousTimeRange = try timeRangeGenerator.unwrapPreviousTimeRange()

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

// MARK: Data - UI mapping
private extension AnalyticsHubViewModel {

    func bindViewModelsWithData() {
        Publishers.CombineLatest($currentOrderStats, $previousOrderStats)
            .sink { [weak self] currentOrderStats, previousOrderStats in
                guard let self else { return }

                self.revenueCard = AnalyticsHubViewModel.revenueCard(currentPeriodStats: currentOrderStats, previousPeriodStats: previousOrderStats)
                self.ordersCard = AnalyticsHubViewModel.ordersCard(currentPeriodStats: currentOrderStats, previousPeriodStats: previousOrderStats)
            }.store(in: &subscriptions)
    }

    static func revenueCard(currentPeriodStats: OrderStatsV4?, previousPeriodStats: OrderStatsV4?) -> AnalyticsReportCardViewModel {
        let totalDelta = StatsDataTextFormatter.createTotalRevenueDelta(from: previousPeriodStats, to: currentPeriodStats)
        let netDelta = StatsDataTextFormatter.createNetRevenueDelta(from: previousPeriodStats, to: currentPeriodStats)

        return AnalyticsReportCardViewModel(title: Localization.RevenueCard.title,
                                            leadingTitle: Localization.RevenueCard.leadingTitle,
                                            leadingValue: StatsDataTextFormatter.createTotalRevenueText(orderStats: currentPeriodStats,
                                                                                                        selectedIntervalIndex: nil),
                                            leadingDelta: totalDelta.string,
                                            leadingDeltaColor: Constants.deltaColor(for: totalDelta.direction),
                                            trailingTitle: Localization.RevenueCard.trailingTitle,
                                            trailingValue: StatsDataTextFormatter.createNetRevenueText(orderStats: currentPeriodStats),
                                            trailingDelta: netDelta.string,
                                            trailingDeltaColor: Constants.deltaColor(for: netDelta.direction))
    }

    static func ordersCard(currentPeriodStats: OrderStatsV4?, previousPeriodStats: OrderStatsV4?) -> AnalyticsReportCardViewModel {
        let ordersCountDelta = StatsDataTextFormatter.createOrderCountDelta(from: previousPeriodStats, to: currentPeriodStats)
        let orderValueDelta = StatsDataTextFormatter.createAverageOrderValueDelta(from: previousPeriodStats, to: currentPeriodStats)

        return AnalyticsReportCardViewModel(title: Localization.OrderCard.title,
                                            leadingTitle: Localization.OrderCard.leadingTitle,
                                            leadingValue: StatsDataTextFormatter.createOrderCountText(orderStats: currentPeriodStats,
                                                                                                      selectedIntervalIndex: nil),
                                            leadingDelta: ordersCountDelta.string,
                                            leadingDeltaColor: Constants.deltaColor(for: ordersCountDelta.direction),
                                            trailingTitle: Localization.OrderCard.trailingTitle,
                                            trailingValue: StatsDataTextFormatter.createAverageOrderValueText(orderStats: currentPeriodStats),
                                            trailingDelta: orderValueDelta.string,
                                            trailingDeltaColor: Constants.deltaColor(for: orderValueDelta.direction))
    }
}

// Mark: - Selection Type
extension AnalyticsHubViewModel {
    enum SelectionType: CaseIterable {
        case today
        case weekToDate
        case monthToDate
        case yearToDate

        var description: String {
            get {
                switch self {
                case .today:
                    return Localization.TimeRangeCard.today
                case .weekToDate:
                    return Localization.TimeRangeCard.weekToDate
                case .monthToDate:
                    return Localization.TimeRangeCard.monthToDate
                case .yearToDate:
                    return Localization.TimeRangeCard.yearToDate
                }
            }
        }

        static func from(_ statsTimeRange: StatsTimeRangeV4) -> SelectionType {
            switch statsTimeRange {
            case .today:
                return .today
            case .thisWeek:
                return .weekToDate
            case .thisMonth:
                return .monthToDate
            case .thisYear:
                return .yearToDate
            }
        }
    }
}

// MARK: - Constants
private extension AnalyticsHubViewModel {
    enum Constants {
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
        enum TimeRangeCard {
            static let today = NSLocalizedString("Today", comment: "Title of the Analytics Hub Today's selection range")
            static let weekToDate = NSLocalizedString("Week to Date", comment: "Title of the Analytics Hub Week to Date selection range")
            static let monthToDate = NSLocalizedString("Month to Date", comment: "Title of the Analytics Hub Month to Date selection range")
            static let yearToDate = NSLocalizedString("Year to Date", comment: "Title of the Analytics Hub Year to Date selection range")
        }
    }
}
