import Foundation
import Yosemite
import WooFoundation

/// Helpers for calculating and displaying Stats V4 data
///
final class StatsV4DataHelper {

    // MARK: Revenue Stats

    /// Creates the text to display for the total revenue.
    ///
    static func createTotalRevenueText(orderStats: OrderStatsV4?,
                                       selectedIntervalIndex: Int?,
                                       currencyFormatter: CurrencyFormatter?,
                                       currencyCode: String) -> String {
        if let revenue = totalRevenue(at: selectedIntervalIndex, orderStats: orderStats) {
            // If revenue is an integer, no decimal points are shown.
            let numberOfDecimals: Int? = revenue.isInteger ? 0: nil
            let currencyFormatter = currencyFormatter ?? CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)
            return currencyFormatter.formatAmount(revenue, with: currencyCode, numberOfDecimals: numberOfDecimals) ?? String()
        } else {
            return Constants.placeholderText
        }
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

    /// Creates the text to display for the average order value.
    ///
    static func createAverageOrderValueText(orderStats: OrderStatsV4?, currencyFormatter: CurrencyFormatter, currencyCode: String) -> String {
        if let value = averageOrderValue(orderStats: orderStats) {
            // If order value is an integer, no decimal points are shown.
            let numberOfDecimals: Int? = value.isInteger ? 0 : nil
            return currencyFormatter.formatAmount(value, with: currencyCode, numberOfDecimals: numberOfDecimals) ?? String()
        } else {
            return Constants.placeholderText
        }
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

    // MARK: Delta Calculations

    /// Creates the text showing the percent change from the previous `Decimal` value to the current `Decimal` value
    ///
    static func createDeltaText(from previousValue: Decimal, to currentValue: Decimal, locale: Locale = Locale.current) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .percent
        numberFormatter.positivePrefix = numberFormatter.plusSign
        numberFormatter.locale = locale

        guard previousValue > 0 else {
            return numberFormatter.string(from: 1) ?? "+100%"
        }

        let deltaValue = ((currentValue - previousValue) / previousValue)
        return numberFormatter.string(from: deltaValue as NSNumber) ?? Constants.placeholderText
    }

    /// Creates the text showing the percent change from the previous `Double` value to the current `Double` value
    ///
    static func createDeltaText(from previousValue: Double, to currentValue: Double, locale: Locale = Locale.current) -> String {
        createDeltaText(from: Decimal(previousValue), to: Decimal(currentValue))
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

private extension StatsV4DataHelper {
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
