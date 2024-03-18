import Foundation
import enum Yosemite.StatsGranularityV4

extension StatsGranularityV4 {
    var displayText: String {
        switch self {
        case .daily:
            NSLocalizedString(
                "statsGranularityV4.dailyMetrics",
                value: "Metrics by day",
                comment: "Display text for the daily granularity of store stats on the My Store screen"
            )
        case .hourly:
            NSLocalizedString(
                "statsGranularityV4.hourlyMetrics",
                value: "Metrics by hour",
                comment: "Display text for the hourly granularity of store stats on the My Store screen"
            )
        case .weekly:
            NSLocalizedString(
                "statsGranularityV4.weeklyMetrics",
                value: "Metrics by week",
                comment: "Display text for the weekly granularity of store stats on the My Store screen"
            )
        case .monthly:
            NSLocalizedString(
                "statsGranularityV4.monthlyMetrics",
                value: "Metrics by month",
                comment: "Display text for the monthly granularity of store stats on the My Store screen"
            )
        case .yearly:
            NSLocalizedString(
                "statsGranularityV4.yearlyMetrics",
                value: "Metrics by year",
                comment: "Display text for the yearly granularity of store stats on the My Store screen"
            )
        }
    }
}
