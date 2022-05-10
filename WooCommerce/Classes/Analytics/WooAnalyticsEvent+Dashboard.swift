import enum Yosemite.StatsTimeRangeV4

extension WooAnalyticsEvent {
    enum Dashboard {
        /// Common event keys.
        private enum Keys {
            static let range = "range"
        }

        static func dashboardMainStatsLoaded(timeRange: StatsTimeRangeV4) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dashboardMainStatsLoaded, properties: [Keys.range: timeRange.analyticsValue])
        }

        static func dashboardMainStatsDate(timeRange: StatsTimeRangeV4) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dashboardMainStatsDate, properties: [Keys.range: timeRange.analyticsValue])
        }

        static func dashboardTopPerformersLoaded(timeRange: StatsTimeRangeV4) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dashboardTopPerformersLoaded, properties: [Keys.range: timeRange.analyticsValue])
        }

        static func dashboardTopPerformersDate(timeRange: StatsTimeRangeV4) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dashboardTopPerformersDate, properties: [Keys.range: timeRange.analyticsValue])
        }
    }
}

private extension StatsTimeRangeV4 {
    var analyticsValue: String {
        switch self {
        case .today:
            return "days"
        case .thisWeek:
            return "weeks"
        case .thisMonth:
            return "months"
        case .thisYear:
            return "years"
        }
    }
}
