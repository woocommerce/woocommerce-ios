import enum Yosemite.StatsTimeRangeV4

extension WooAnalyticsEvent {
    enum Dashboard {
        /// Common event keys.
        private enum Keys {
            static let range = "range"
        }

        /// Tracked when the store stats are loaded with fresh data either via first load, event driven refresh, or manual refresh.
        /// - Parameter timeRange: the range of store stats (e.g. Today, This Week, This Month, This Year).
        static func dashboardMainStatsLoaded(timeRange: StatsTimeRangeV4) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dashboardMainStatsLoaded, properties: [Keys.range: timeRange.analyticsValue])
        }

        /// Tracked when the date range on the store stats view changes.
        /// - Parameter timeRange: the range of store stats (e.g. Today, This Week, This Month, This Year).
        static func dashboardMainStatsDate(timeRange: StatsTimeRangeV4) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dashboardMainStatsDate, properties: [Keys.range: timeRange.analyticsValue])
        }

        /// Tracked when the top performers are loaded with fresh data either via first load, event driven refresh, or manual refresh.
        /// - Parameter timeRange: the range of store stats (e.g. Today, This Week, This Month, This Year).
        static func dashboardTopPerformersLoaded(timeRange: StatsTimeRangeV4) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dashboardTopPerformersLoaded, properties: [Keys.range: timeRange.analyticsValue])
        }

        /// Tracked when the date range on the top performers view changes.
        /// - Parameter timeRange: the range of store stats (e.g. Today, This Week, This Month, This Year).
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
