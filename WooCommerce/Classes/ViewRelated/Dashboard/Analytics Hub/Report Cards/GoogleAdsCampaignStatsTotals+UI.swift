import Foundation
import struct Yosemite.GoogleAdsCampaignStatsTotals

extension GoogleAdsCampaignStatsTotals.TotalData {
    /// Localized name to display for each of the total data stats.
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

    /// Identifier for each of the total data stats to use in Tracks events.
    var tracksIdentifier: String {
        self.rawValue
    }
}

private enum Localization {
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
