import Foundation
import Yosemite
import WooFoundation

/// Helpers for calculating and formatting stats data for display.
///
struct StatsDataTextFormatter {

    // MARK: Revenue Stats

    /// Creates the text to display for the total revenue.
    ///
    static func createTotalRevenueText(orderStats: OrderStatsV4?,
                                       selectedIntervalIndex: Int?,
                                       currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
                                       currencyCode: String = ServiceLocator.currencySettings.currencyCode.rawValue) -> String {
        if let revenue = totalRevenue(at: selectedIntervalIndex, orderStats: orderStats) {
            // If revenue is an integer, no decimal points are shown.
            let numberOfDecimals: Int? = revenue.rounded(to: 2).isInteger ? 0 : nil
            return currencyFormatter.formatAmount(revenue, with: currencyCode, numberOfDecimals: numberOfDecimals) ?? String()
        } else {
            return Constants.placeholderText
        }
    }

    /// Creates the text to display for the total revenue delta.
    ///
    static func createTotalRevenueDelta(from previousPeriod: OrderStatsV4?, to currentPeriod: OrderStatsV4?) -> DeltaPercentage {
        let previousRevenue = totalRevenue(at: nil, orderStats: previousPeriod)
        let currentRevenue = totalRevenue(at: nil, orderStats: currentPeriod)
        return createDeltaPercentage(from: previousRevenue, to: currentRevenue)
    }

    /// Creates the text to display for the net revenue.
    ///
    static func createNetRevenueText(orderStats: OrderStatsV4?,
                                     currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
                                     currencyCode: String = ServiceLocator.currencySettings.currencyCode.rawValue) -> String {
        guard let revenue = orderStats?.totals.netRevenue else {
            return Constants.placeholderText
        }

        // If revenue is an integer, no decimal points are shown.
        let numberOfDecimals: Int? = revenue.rounded(to: 2).isInteger ? 0 : nil
        return currencyFormatter.formatAmount(revenue, with: currencyCode, numberOfDecimals: numberOfDecimals) ?? String()
    }

    /// Creates the text to display for the net revenue delta.
    ///
    static func createNetRevenueDelta(from previousPeriod: OrderStatsV4?, to currentPeriod: OrderStatsV4?) -> DeltaPercentage {
        let previousRevenue = previousPeriod?.totals.netRevenue
        let currentRevenue = currentPeriod?.totals.netRevenue
        return createDeltaPercentage(from: previousRevenue, to: currentRevenue)
    }

    // MARK: Orders Stats

    /// Creates the text to display for the order count.
    ///
    static func createOrderCountText(orderStats: OrderStatsV4?, selectedIntervalIndex: Int?) -> String {
        if let count = orderCount(at: selectedIntervalIndex, orderStats: orderStats) {
            return Double(count).humanReadableString()
        } else {
            return Constants.placeholderText
        }
    }

    /// Creates the text to display for the order count delta.
    ///
    static func createOrderCountDelta(from previousPeriod: OrderStatsV4?, to currentPeriod: OrderStatsV4?) -> DeltaPercentage {
        let previousCount = orderCount(at: nil, orderStats: previousPeriod)
        let currentCount = orderCount(at: nil, orderStats: currentPeriod)
        return createDeltaPercentage(from: previousCount, to: currentCount)
    }

    /// Creates the text to display for the average order value.
    ///
    static func createAverageOrderValueText(orderStats: OrderStatsV4?,
                                            currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
                                            currencyCode: String = ServiceLocator.currencySettings.currencyCode.rawValue) -> String {
        if let value = averageOrderValue(orderStats: orderStats) {
            // If order value is an integer, no decimal points are shown.
            let numberOfDecimals: Int? = value.rounded(to: 2).isInteger ? 0 : nil
            return currencyFormatter.formatAmount(value, with: currencyCode, numberOfDecimals: numberOfDecimals) ?? String()
        } else {
            return Constants.placeholderText
        }
    }

    /// Creates the text to display for the average order value delta.
    ///
    static func createAverageOrderValueDelta(from previousPeriod: OrderStatsV4?, to currentPeriod: OrderStatsV4?) -> DeltaPercentage {
        let previousAverage = averageOrderValue(orderStats: previousPeriod)
        let currentAverage = averageOrderValue(orderStats: currentPeriod)
        return createDeltaPercentage(from: previousAverage, to: currentAverage)
    }

    // MARK: Views and Visitors Stats

    /// Creates the text to display for the visitor count.
    ///
    static func createVisitorCountText(siteStats: SiteVisitStats?, selectedIntervalIndex: Int?) -> String {
        if let visitorCount = visitorCount(at: selectedIntervalIndex, siteStats: siteStats) {
            return Double(visitorCount).humanReadableString()
        } else {
            return Constants.placeholderText
        }
    }

    /// Creates the text to display for the visitor count delta.
    ///
    static func createVisitorCountDelta(from previousPeriod: SiteVisitStats?, to currentPeriod: SiteVisitStats?) -> DeltaPercentage {
        let previousCount = visitorCount(at: nil, siteStats: previousPeriod)
        let currentCount = visitorCount(at: nil, siteStats: currentPeriod)
        return createDeltaPercentage(from: previousCount, to: currentCount)
    }

    // MARK: Conversion Stats

    /// Creates the text to display for the conversion rate.
    ///
    static func createConversionRateText(orderStats: OrderStatsV4?, siteStats: SiteVisitStats?, selectedIntervalIndex: Int?) -> String {
        let visitors = visitorCount(at: selectedIntervalIndex, siteStats: siteStats)
        let orders = orderCount(at: selectedIntervalIndex, orderStats: orderStats)

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .percent
        numberFormatter.minimumFractionDigits = 1

        if let visitors, let orders {
            // Maximum conversion rate is 100%.
            let conversionRate = visitors > 0 ? min(orders/visitors, 1): 0
            let minimumFractionDigits = floor(conversionRate * 100.0) == conversionRate * 100.0 ? 0: 1
            numberFormatter.minimumFractionDigits = minimumFractionDigits
            return numberFormatter.string(from: conversionRate as NSNumber) ?? Constants.placeholderText
        } else {
            return Constants.placeholderText
        }
    }
}

extension StatsDataTextFormatter {

    // MARK: Delta Calculations

    /// Creates the `DeltaPercentage` for the percent change from the previous `Decimal` value to the current `Decimal` value
    ///
    static func createDeltaPercentage(from previousValue: Decimal?, to currentValue: Decimal?) -> DeltaPercentage {
        guard let previousValue, let currentValue, previousValue != currentValue else {
            return DeltaPercentage(value: 0) // Missing or equal values: 0% change
        }

        // If the previous value was 0, return a 100% or -100% change
        guard previousValue != 0 else {
            let deltaValue: Decimal = currentValue > 0 ? 1 : -1
            return DeltaPercentage(value: deltaValue)
        }

        return DeltaPercentage(value: (currentValue - previousValue) / previousValue)
    }

    /// Creates the `DeltaPercentage` for the percent change from the previous `Double` value to the current `Double` value
    ///
    static func createDeltaPercentage(from previousValue: Double?, to currentValue: Double?) -> DeltaPercentage {
        guard let previousValue, let currentValue else {
            return DeltaPercentage(value: 0) // Missing data: 0% change
        }

        return createDeltaPercentage(from: Decimal(previousValue), to: Decimal(currentValue))
    }

    /// Represents a formatted delta percentage string and its direction of change
    struct DeltaPercentage {
        /// The delta percentage formatted as a localized string (e.g. `+100%`)
        let string: String

        /// The direction of change
        let direction: Direction

        init(value: Decimal) {
            self.string = deltaNumberFormatter.string(from: value as NSNumber) ?? Constants.placeholderText
            self.direction = {
                if value > 0 {
                    return .positive
                } else if value < 0 {
                    return .negative
                } else {
                    return .zero
                }
            }()
        }

        /// Represents the direction of change for a delta value
        enum Direction {
            case positive
            case negative
            case zero
        }
    }

    // MARK: Stats Intervals

    /// Returns the order stats intervals, ordered by date.
    ///
    static func sortOrderStatsIntervals(from orderStats: OrderStatsV4?) -> [OrderStatsV4Interval] {
        return orderStats?.intervals.sorted(by: { (lhs, rhs) -> Bool in
            let siteTimezone = TimeZone.siteTimezone
            return lhs.dateStart(timeZone: siteTimezone) < rhs.dateStart(timeZone: siteTimezone)
        }) ?? []
    }
}

// MARK: - Private helpers

private extension StatsDataTextFormatter {

    /// Number formatter for delta percentages, e.g. `+36%` or `-16%`.
    ///
    static let deltaNumberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .percent
        numberFormatter.positivePrefix = numberFormatter.plusSign
        return numberFormatter
    }()

    /// Retrieves the visitor count for the provided order stats and, optionally, a specific interval.
    ///
    static func visitorCount(at selectedIndex: Int?, siteStats: SiteVisitStats?) -> Double? {
        let siteStatsItems = siteStats?.items?.sorted(by: { (lhs, rhs) -> Bool in
            return lhs.period < rhs.period
        }) ?? []
        if let selectedIndex, selectedIndex < siteStatsItems.count {
            return Double(siteStatsItems[selectedIndex].visitors)
        } else if let siteStats {
            return Double(siteStats.totalVisitors)
        } else {
            return nil
        }
    }

    /// Retrieves the order count for the provided order stats and, optionally, a specific interval.
    ///
    static func orderCount(at selectedIndex: Int?, orderStats: OrderStatsV4?) -> Double? {
        let orderStatsIntervals = sortOrderStatsIntervals(from: orderStats)
        if let selectedIndex, selectedIndex < orderStatsIntervals.count {
            let orderStats = orderStatsIntervals[selectedIndex]
            return Double(orderStats.subtotals.totalOrders)
        } else if let orderStats {
            return Double(orderStats.totals.totalOrders)
        } else {
            return nil
        }
    }

    /// Retrieves the average order value for the provided order stats.
    ///
    static func averageOrderValue(orderStats: OrderStatsV4?) -> Decimal? {
        if let orderStats {
            return orderStats.totals.averageOrderValue
        } else {
            return nil
        }
    }

    /// Retrieves the total revenue from the provided order stats and, optionally, a specific interval.
    ///
    static func totalRevenue(at selectedIndex: Int?, orderStats: OrderStatsV4?) -> Decimal? {
        let orderStatsIntervals = sortOrderStatsIntervals(from: orderStats)
        if let selectedIndex, selectedIndex < orderStatsIntervals.count {
            let orderStats = orderStatsIntervals[selectedIndex]
            return orderStats.subtotals.grossRevenue
        } else if let orderStats {
            return orderStats.totals.grossRevenue
        } else {
            return nil
        }
    }

    enum Constants {
        static let placeholderText = "-"
    }


}

private extension Decimal {
    func rounded(to scale: Int16) -> Self {
        let numberHandler = NSDecimalNumberHandler(roundingMode: .plain,
                                                   scale: scale,
                                                   raiseOnExactness: false,
                                                   raiseOnOverflow: false,
                                                   raiseOnUnderflow: false,
                                                   raiseOnDivideByZero: false)
        return (self as NSDecimalNumber).rounding(accordingToBehavior: numberHandler) as Decimal
    }
}
