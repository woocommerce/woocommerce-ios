import Codegen

/// Represents the data associated with Google Listings & Ads paid campaign stats over a specific period.
public struct GoogleAdsCampaignStatsTotals: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable, WCAnalyticsStatsTotals {
    /// Amount in sales attributed to ads campaign
    public let sales: Decimal?

    /// Amount spent on ads campaign
    public let spend: Decimal?

    /// Number of clicks on ads campaign
    public let clicks: Int?

    /// Number of impressions of ads campaign
    public let impressions: Int?

    /// Number of conversions from ads campaign
    public let conversions: Decimal?

    public init(sales: Decimal?,
                spend: Decimal?,
                clicks: Int?,
                impressions: Int?,
                conversions: Decimal?) {
        self.sales = sales
        self.spend = spend
        self.clicks = clicks
        self.impressions = impressions
        self.conversions = conversions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let sales = try container.decodeIfPresent(Decimal.self, forKey: .sales)
        let spend = try container.decodeIfPresent(Decimal.self, forKey: .spend)
        let clicks = try container.decodeIfPresent(Int.self, forKey: .clicks)
        let impressions = try container.decodeIfPresent(Int.self, forKey: .impressions)
        let conversions = try container.decodeIfPresent(Decimal.self, forKey: .conversions)

        self.init(sales: sales,
                  spend: spend,
                  clicks: clicks,
                  impressions: impressions,
                  conversions: conversions)
    }
}


// MARK: - Constants!
//
private extension GoogleAdsCampaignStatsTotals {
    enum CodingKeys: String, CodingKey {
        case sales
        case spend
        case clicks
        case impressions
        case conversions
    }
}
