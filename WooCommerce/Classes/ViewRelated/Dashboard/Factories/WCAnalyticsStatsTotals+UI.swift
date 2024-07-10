import Yosemite

/// Protocol for `WCAnalyticsStatsTotals` that can be parsed with the `StatsIntervalDataParser`
protocol ParsableStatsTotals: WCAnalyticsStatsTotals {
    /// Represents the types of stats total data
    associatedtype TotalData: RawRepresentable

    /// Gets the double value for the given stats total data type
    func getDoubleValue(for data: TotalData) -> Double
}

// MARK: - Parsable Order Stats V4

extension OrderStatsV4Totals: ParsableStatsTotals {
    /// Represents a type of orders total data
    enum TotalData: String {
        case totalOrders
        case totalItemsSold
        case grossRevenue
        case netRevenue
        case averageOrderValue
    }

    func getDoubleValue(for data: TotalData) -> Double {
        switch data {
        case .totalOrders:
            return Double(totalOrders)
        case .totalItemsSold:
            return Double(totalItemsSold)
        case .grossRevenue:
            return (grossRevenue as NSNumber).doubleValue
        case .netRevenue:
            return (netRevenue as NSNumber).doubleValue
        case .averageOrderValue:
            return (averageOrderValue as NSNumber).doubleValue
        }
    }
}

// MARK: - Parsable Product Bundle Stats

extension ProductBundleStatsTotals: ParsableStatsTotals {
    /// Represents a type of product bundles total data
    enum TotalData: String {
        case totalItemsSold
        case totalBundledItemsSold
        case netRevenue
        case totalOrders
        case totalProducts
    }

    func getDoubleValue(for data: TotalData) -> Double {
        switch data {
        case .totalItemsSold:
            return Double(totalItemsSold)
        case .totalBundledItemsSold:
            return Double(totalBundledItemsSold)
        case .netRevenue:
            return (netRevenue as NSNumber).doubleValue
        case .totalOrders:
            return Double(totalOrders)
        case .totalProducts:
            return Double(totalProducts)
        }
    }
}

// MARK: - Parsable Gift Card Stats

extension GiftCardStatsTotals: ParsableStatsTotals {
    /// Represents a type of gift cards total data
    enum TotalData: Double {
        case giftCardsCount
        case usedAmount
        case refundedAmount
        case netAmount
    }

    func getDoubleValue(for data: TotalData) -> Double {
        switch data {
        case .giftCardsCount:
            return Double(giftCardsCount)
        case .usedAmount:
            return (usedAmount as NSNumber).doubleValue
        case .refundedAmount:
            return (refundedAmount as NSNumber).doubleValue
        case .netAmount:
            return (netAmount as NSNumber).doubleValue
        }
    }
}

// MARK: - Parsable Google Ads Campaigns Stats

extension GoogleAdsCampaignStatsTotals: ParsableStatsTotals {
    /// Represents a type of Google Ads campaigns total data
    enum TotalData: Double, CaseIterable {
        case sales
        case spend
        case clicks
        case impressions
        case conversions

        var displayName: String {
            switch self {
            case .sales:
                Localization.sales
            case .spend:
                Localization.spend
            case .clicks:
                Localization.clicks
            case .impressions:
                Localization.impressions
            case .conversions:
                Localization.conversions
            }
        }
    }

    func getDoubleValue(for data: TotalData) -> Double {
        switch data {
        case .sales:
            ((sales ?? 0) as NSNumber).doubleValue
        case .spend:
            ((spend ?? 0) as NSNumber).doubleValue
        case .clicks:
            Double(clicks ?? 0)
        case .impressions:
            Double(impressions ?? 0)
        case .conversions:
            ((conversions ?? 0) as NSNumber).doubleValue
        }
    }
}

private extension GoogleAdsCampaignStatsTotals {
    enum Localization {
        static let sales = NSLocalizedString("googleAdsCampaignStatsTotals.totalData.sales",
                                             value: "Total Sales",
                                             comment: "Display name for the total sales stat in Google Ads campaign stats")
        static let spend = NSLocalizedString("googleAdsCampaignStatsTotals.totalData.spend",
                                             value: "Total Spend",
                                             comment: "Display name for the total spend stat in Google Ads campaign stats")
        static let clicks = NSLocalizedString("googleAdsCampaignStatsTotals.totalData.clicks",
                                              value: "Clicks",
                                              comment: "Display name for the clicks stat in Google Ads campaign stats")
        static let impressions = NSLocalizedString("googleAdsCampaignStatsTotals.totalData.impressions",
                                                   value: "Impressions",
                                                   comment: "Display name for the impressions stat in Google Ads campaign stats")
        static let conversions = NSLocalizedString("googleAdsCampaignStatsTotals.totalData.conversions",
                                                   value: "Conversions",
                                                   comment: "Display name for the conversions stat in Google Ads campaign stats")
    }
}
