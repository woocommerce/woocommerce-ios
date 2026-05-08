extension StoreStatsWidgetDateRange {
    /// Maps the user-selected widget range to the primitive parameters consumed by
    /// `StoreInfoDataService.fetchStats(for:dateRange:)`.
    ///
    var serviceDateRange: StoreInfoDataService.DateRange {
        switch self {
        case .today:
            return .today()
        case .last7Days:
            return .last7Days()
        case .last30Days:
            return .last30Days()
        }
    }
}
