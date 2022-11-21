import Foundation
import Yosemite
import WooFoundation

/// Helpers for calculating and displaying Stats V4 data
///
final class StatsV4DataHelper {
    typealias OrderStatsData = (stats: OrderStatsV4?, intervals: [OrderStatsV4Interval])

    // MARK: Revenue Stats

    /// Creates the text to display for the total revenue.
    ///
    static func createTotalRevenueText(orderStatsData: OrderStatsData,
                                       selectedIntervalIndex: Int?,
                                       currencyFormatter: CurrencyFormatter?,
                                       currencyCode: String) -> String {
        if let revenue = totalRevenue(at: selectedIntervalIndex, orderStats: orderStatsData.stats, orderStatsIntervals: orderStatsData.intervals) {
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
    static func createOrderCountText(orderStatsData: OrderStatsData, selectedIntervalIndex: Int?) -> String {
        if let count = orderCount(at: selectedIntervalIndex, orderStats: orderStatsData.stats, orderStatsIntervals: orderStatsData.intervals) {
            return Double(count).humanReadableString()
        } else {
            return Constants.placeholderText
        }
    }

    /// Creates the text to display for the average order value.
    ///
    static func createAverageOrderValueText(orderStatsData: OrderStatsData, currencyFormatter: CurrencyFormatter, currencyCode: String) -> String {
        if let value = averageOrderValue(orderStats: orderStatsData.stats) {
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
    static func createConversionRateText(orderStatsData: OrderStatsData, siteStats: SiteVisitStats?, selectedIntervalIndex: Int?) -> String {
        let visitors = visitorCount(at: selectedIntervalIndex, siteStats: siteStats)
        let orders = orderCount(at: selectedIntervalIndex, orderStats: orderStatsData.stats, orderStatsIntervals: orderStatsData.intervals)

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
    static func orderCount(at selectedIndex: Int?, orderStats: OrderStatsV4?, orderStatsIntervals: [OrderStatsV4Interval]) -> Double? {
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
    static func totalRevenue(at selectedIndex: Int?, orderStats: OrderStatsV4?, orderStatsIntervals: [OrderStatsV4Interval]) -> Decimal? {
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
