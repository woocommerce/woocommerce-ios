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
        return formatAmount(totalRevenue(at: selectedIntervalIndex, orderStats: orderStats),
                            currencyFormatter: currencyFormatter,
                            currencyCode: currencyCode,
                            numberOfFractionDigits: numberOfFractionDigits)
    }

    /// Creates the text to display for the net revenue.
    ///
    static func createNetRevenueText(orderStats: OrderStatsV4?,
                                     currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
                                     currencyCode: String = ServiceLocator.currencySettings.currencyCode.rawValue,
                                     numberOfFractionDigits: Int = ServiceLocator.currencySettings.fractionDigits) -> String {
        return formatAmount(orderStats?.totals.netRevenue,
                            currencyFormatter: currencyFormatter,
                            currencyCode: currencyCode,
                            numberOfFractionDigits: numberOfFractionDigits)
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
    static func createAverageOrderValueText(orderStats: OrderStatsV4?,
                                            currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
                                            currencyCode: String = ServiceLocator.currencySettings.currencyCode.rawValue,
                                            numberOfFractionDigits: Int = ServiceLocator.currencySettings.fractionDigits) -> String {
        return formatAmount(averageOrderValue(orderStats: orderStats),
                            currencyFormatter: currencyFormatter,
                            currencyCode: currencyCode,
                            numberOfFractionDigits: numberOfFractionDigits)
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

    // MARK: Bundles Stats

    /// Creates the text to display for bundles sold value.
    ///
    static func createBundlesSoldText(bundleStats: ProductBundleStats?) -> String {
        guard let bundleStats else {
            return Constants.placeholderText
        }
        return Double(bundleStats.totals.totalItemsSold).humanReadableString()
    }

    // MARK: Gift Card Stats

    /// Creates the text to display for gift cards used value.
    ///
    static func createGiftCardsUsedText(giftCardStats: GiftCardStats?) -> String {
        guard let giftCardStats else {
            return Constants.placeholderText
        }
        return Double(giftCardStats.totals.giftCardsCount).humanReadableString()
    }

    /// Creates the text to display for gift cards net amount value.
    ///
    static func createGiftCardsNetAmountText(giftCardStats: GiftCardStats?,
                                             currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
                                             currencyCode: String = ServiceLocator.currencySettings.currencyCode.rawValue,
                                             numberOfFractionDigits: Int = ServiceLocator.currencySettings.fractionDigits) -> String {
        return formatAmount(giftCardStats?.totals.netAmount,
                            currencyFormatter: currencyFormatter,
                            currencyCode: currencyCode,
                            numberOfFractionDigits: numberOfFractionDigits)
    }

    // MARK: Google Ads Campaign Stats

    /// Creates the text to display for a campaign stats metric, from the provided stats.
    ///
    static func createGoogleCampaignsStatText(for stat: GoogleAdsCampaignStatsTotals.TotalData,
                                              from campaignStats: GoogleAdsCampaignStats?,
                                              currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
                                              currencyCode: String = ServiceLocator.currencySettings.currencyCode.rawValue,
                                              numberOfFractionDigits: Int = ServiceLocator.currencySettings.fractionDigits) -> String {
        guard let campaignStats else {
            return Constants.placeholderText
        }
        switch stat {
        case .sales:
            return formatAmount(campaignStats.totals.sales,
                         currencyFormatter: currencyFormatter,
                         currencyCode: currencyCode,
                         numberOfFractionDigits: numberOfFractionDigits)
        case .spend:
            return formatAmount(campaignStats.totals.spend,
                         currencyFormatter: currencyFormatter,
                         currencyCode: currencyCode,
                         numberOfFractionDigits: numberOfFractionDigits)
        case .clicks, .impressions, .conversions:
            return NumberFormatter.localizedString(from: campaignStats.totals.getDoubleValue(for: stat) as NSNumber) ?? Constants.placeholderText
        }
    }

    /// Creates the text to display for a campaign stat subtotal, from the provided campaign.
    ///
    static func createGoogleCampaignsSubtotalText(for stat: GoogleAdsCampaignStatsTotals.TotalData,
                                                  from campaign: GoogleAdsCampaignStatsItem,
                                                  currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
                                                  currencyCode: String = ServiceLocator.currencySettings.currencyCode.rawValue,
                                                  numberOfFractionDigits: Int = ServiceLocator.currencySettings.fractionDigits) -> String {
        switch stat {
        case .sales:
            formatAmount(campaign.subtotals.sales,
                         currencyFormatter: currencyFormatter,
                         currencyCode: currencyCode,
                         numberOfFractionDigits: numberOfFractionDigits)
        case .spend:
            formatAmount(campaign.subtotals.spend,
                         currencyFormatter: currencyFormatter,
                         currencyCode: currencyCode,
                         numberOfFractionDigits: numberOfFractionDigits)
        case .clicks, .impressions, .conversions:
            NumberFormatter.localizedString(from: campaign.subtotals.getDoubleValue(for: stat) as NSNumber) ?? Constants.placeholderText
        }
    }

    // MARK: Generic helpers

    /// Creates the text to display for an amount with currency settings.
    ///
    /// If the amount is an integer, no decimal points are shown, e.g. `$12.34` or `$12` (not `$12.00`).
    ///
    static func formatAmount(_ amount: Decimal?,
                             currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
                             currencyCode: String = ServiceLocator.currencySettings.currencyCode.rawValue,
                             numberOfFractionDigits: Int = ServiceLocator.currencySettings.fractionDigits) -> String {
        guard let amount else {
            return Constants.placeholderText
        }
        // If amount is an integer, no decimal points are shown.
        let numberOfDecimals: Int? = amount.rounded(.plain, scale: numberOfFractionDigits).isInteger ? 0 : nil
        return currencyFormatter.formatAmount(amount, with: currencyCode, numberOfDecimals: numberOfDecimals) ?? String()
    }
}

extension StatsDataTextFormatter {

    // MARK: Delta Calculations

    static func createDelta<Stats: WCAnalyticsStats>(for totalData: Stats.Totals.TotalData,
                                                     from previousPeriod: Stats?,
                                                     to currentPeriod: Stats?) -> DeltaPercentage where Stats.Totals: ParsableStatsTotals {
        guard let previousPeriod, let currentPeriod else {
            return DeltaPercentage(value: 0, formatter: deltaNumberFormatter) // Missing data: 0% change
        }
        let previousTotal = previousPeriod.totals.getDoubleValue(for: totalData)
        let currentTotal = currentPeriod.totals.getDoubleValue(for: totalData)
        return createDeltaPercentage(from: previousTotal, to: currentTotal)
    }

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
        let orderStatsIntervals = StatsIntervalDataParser.sortStatsIntervals(from: orderStats)
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
        let orderStatsIntervals = StatsIntervalDataParser.sortStatsIntervals(from: orderStats)
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
