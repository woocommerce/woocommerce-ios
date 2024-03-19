import Foundation
import enum Yosemite.StatsGranularityV4

extension StatsGranularityV4 {
    var displayText: String {
        switch self {
        case .daily:
            NSLocalizedString(
                "statsGranularityV4.dailyMetrics",
                value: "Daily intervals",
                comment: "Display text for the daily granularity of store stats on the My Store screen"
            )
        case .hourly:
            NSLocalizedString(
                "statsGranularityV4.hourlyMetrics",
                value: "Hourly intervals",
                comment: "Display text for the hourly granularity of store stats on the My Store screen"
            )
        case .weekly:
            NSLocalizedString(
                "statsGranularityV4.weeklyMetrics",
                value: "Weekly intervals",
                comment: "Display text for the weekly granularity of store stats on the My Store screen"
            )
        case .monthly:
            NSLocalizedString(
                "statsGranularityV4.monthlyMetrics",
                value: "Monthly intervals",
                comment: "Display text for the monthly granularity of store stats on the My Store screen"
            )
        case .yearly:
            NSLocalizedString(
                "statsGranularityV4.yearlyMetrics",
                value: "Yearly intervals",
                comment: "Display text for the yearly granularity of store stats on the My Store screen"
            )
        }
    }
}
