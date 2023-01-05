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
                                       currencyCode: String = ServiceLocator.currencySettings.currencyCode.rawValue,
                                       numberOfFractionDigits: Int = ServiceLocator.currencySettings.fractionDigits) -> String {
        if let revenue = totalRevenue(at: selectedIntervalIndex, orderStats: orderStats) {
            // If revenue is an integer, no decimal points are shown.
            let numberOfDecimals: Int? = revenue.rounded(.plain, scale: numberOfFractionDigits).isInteger ? 0 : nil
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
                                     currencyCode: String = ServiceLocator.currencySettings.currencyCode.rawValue,
                                     numberOfFractionDigits: Int = ServiceLocator.currencySettings.fractionDigits) -> String {
        guard let revenue = orderStats?.totals.netRevenue else {
            return Constants.placeholderText
        }

        // If revenue is an integer, no decimal points are shown.
        let numberOfDecimals: Int? = revenue.rounded(.plain, scale: numberOfFractionDigits).isInteger ? 0 : nil
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
                                            currencyCode: String = ServiceLocator.currencySettings.currencyCode.rawValue,
                                            numberOfFractionDigits: Int = ServiceLocator.currencySettings.fractionDigits) -> String {
        if let value = averageOrderValue(orderStats: orderStats) {
            // If order value is an integer, no decimal points are shown.
            let numberOfDecimals: Int? = value.rounded(.plain, scale: numberOfFractionDigits).isInteger ? 0 : nil
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

    /// Creates the text to display for the visitor count based on SiteVisitStats data and a given interval.
    ///
    static func createVisitorCountText(siteStats: SiteVisitStats?, selectedIntervalIndex: Int) -> String {
        if let visitorCount = visitorCount(at: selectedIntervalIndex, siteStats: siteStats) {
            return Double(visitorCount).humanReadableString()
        } else {
            return Constants.placeholderText
        }
    }

    /// Creates the text to display for the visitor count based on SiteSummaryStats data.
    ///
    static func createVisitorCountText(siteStats: SiteSummaryStats?) -> String {
        guard let visitorCount = siteStats?.visitors else {
            return Constants.placeholderText
        }

        return Double(visitorCount).humanReadableString()
    }

    /// Creates the text to display for the views count.
    ///
    static func createViewsCountText(siteStats: SiteSummaryStats?) -> String {
        guard let viewsCount = siteStats?.views else {
            return Constants.placeholderText
        }

        return Double(viewsCount).humanReadableString()
    }

    // MARK: Conversion Stats

    /// Creates the text to display for the conversion rate based on SiteVisitStats data and a given interval.
    ///
    static func createConversionRateText(orderStats: OrderStatsV4?, siteStats: SiteVisitStats?, selectedIntervalIndex: Int) -> String {
        guard let visitors = visitorCount(at: selectedIntervalIndex, siteStats: siteStats),
              let orders = orderCount(at: selectedIntervalIndex, orderStats: orderStats) else {
            return Constants.placeholderText
        }

        return createConversionRateText(converted: orders, total: visitors)
    }

    /// Creates the text to display for the conversion rate based on SiteSummaryStats data.
    ///
    static func createConversionRateText(orderStats: OrderStatsV4?, siteStats: SiteSummaryStats?) -> String {
        guard let visitors = siteStats?.visitors, let orders = orderStats?.totals.totalOrders else {
            return Constants.placeholderText
        }

        return createConversionRateText(converted: Double(orders), total: Double(visitors))
    }

    // MARK: Product Stats

    /// Creates the text to display for all of items sold value.
    ///
    static func createItemsSoldText(orderStats: OrderStatsV4?) -> String {
        guard let orderStats else {
            return Constants.placeholderText
        }
        return Double(orderStats.totals.totalItemsSold).humanReadableString()
    }

    /// Creates the text to display for the orders item sold delta.
    ///
    static func createOrderItemsSoldDelta(from previousPeriod: OrderStatsV4?, to currentPeriod: OrderStatsV4?) -> DeltaPercentage {
        guard let previousPeriod, let currentPeriod else {
            return DeltaPercentage(value: 0, formatter: deltaNumberFormatter) // Missing data: 0% change
        }
        let previousItemsSold = Double(previousPeriod.totals.totalItemsSold)
        let currentItemsSold = Double(currentPeriod.totals.totalItemsSold)
        return createDeltaPercentage(from: previousItemsSold, to: currentItemsSold)
    }
}

extension StatsDataTextFormatter {

    // MARK: Delta Calculations

    /// Creates the `DeltaPercentage` for the percent change from the previous `Decimal` value to the current `Decimal` value
    ///
    static func createDeltaPercentage(from previousValue: Decimal?, to currentValue: Decimal?) -> DeltaPercentage {
        guard let previousValue, let currentValue, previousValue != currentValue else {
            return DeltaPercentage(value: 0, formatter: deltaNumberFormatter) // Missing or equal values: 0% change
        }

        // If the previous value was 0, return a 100% or -100% change
        guard previousValue != 0 else {
            let deltaValue: Decimal = currentValue > 0 ? 1 : -1
            return DeltaPercentage(value: deltaValue, formatter: deltaNumberFormatter)
        }

        return DeltaPercentage(value: (currentValue - previousValue) / previousValue, formatter: deltaNumberFormatter)
    }

    /// Creates the `DeltaPercentage` for the percent change from the previous `Double` value to the current `Double` value
    ///
    static func createDeltaPercentage(from previousValue: Double?, to currentValue: Double?) -> DeltaPercentage {
        guard let previousValue, let currentValue else {
            return DeltaPercentage(value: 0, formatter: deltaNumberFormatter) // Missing data: 0% change
        }

        return createDeltaPercentage(from: Decimal(previousValue), to: Decimal(currentValue))
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

    /// Retrieves the visitor count for the provided site stats and a specific interval.
    ///
    static func visitorCount(at selectedIndex: Int, siteStats: SiteVisitStats?) -> Double? {
        let siteStatsItems = siteStats?.items?.sorted(by: { (lhs, rhs) -> Bool in
            return lhs.period < rhs.period
        }) ?? []
        if selectedIndex < siteStatsItems.count {
            return Double(siteStatsItems[selectedIndex].visitors)
        } else {
            return nil
        }
    }

    /// Retrieves the order count for the provided order stats and, optionally, a specific interval.
    ///
    static func orderCount(at selectedIndex: Int?, orderStats: OrderStatsV4?) -> Double? {
        let orderStatsIntervals = StatsIntervalDataParser.sortOrderStatsIntervals(from: orderStats)
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
        let orderStatsIntervals = StatsIntervalDataParser.sortOrderStatsIntervals(from: orderStats)
        if let selectedIndex, selectedIndex < orderStatsIntervals.count {
            let orderStats = orderStatsIntervals[selectedIndex]
            return orderStats.subtotals.grossRevenue
        } else if let orderStats {
            return orderStats.totals.grossRevenue
        } else {
            return nil
        }
    }

    /// Creates the text to display for the conversion rate from 2 input values.
    ///
    static func createConversionRateText(converted: Double, total: Double) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .percent
        numberFormatter.minimumFractionDigits = 1

        // Maximum conversion rate is 100%.
        let conversionRate = total > 0 ? min(converted/total, 1) : 0
        let minimumFractionDigits = floor(conversionRate * 100.0) == conversionRate * 100.0 ? 0 : 1
        numberFormatter.minimumFractionDigits = minimumFractionDigits
        return numberFormatter.string(from: conversionRate as NSNumber) ?? Constants.placeholderText
    }

    enum Constants {
        static let placeholderText = "-"
    }
}
