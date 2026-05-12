extension StoreStatsWidgetDateRange {
    /// Maps the user-selected widget range to the primitive parameters consumed by
    /// `StoreInfoDataService.fetchStats(for:dateRange:)`.
    var serviceDateRange: StoreInfoDataService.DateRange {
        switch self {
        case .today:
            return .today()
        case .yesterday:
            return .yesterday()
        case .lastWeek:
            return .lastWeek()
        case .lastMonth:
            return .lastMonth()
        case .weekToDate:
            return .weekToDate()
        case .monthToDate:
            return .monthToDate()
        }
    }
}
