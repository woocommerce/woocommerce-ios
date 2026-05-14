import Foundation

extension StoreStatsWidgetDateRange {
    /// Maps the user-selected widget range to the primitive parameters consumed by
    /// `StoreInfoDataService.fetchStats(for:dateRange:)`, using the selected store's timezone.
    func serviceDateRange(timezone: TimeZone = .current) -> StoreInfoDataService.DateRange {
        switch self {
        case .today:
            return .today(timezone: timezone)
        case .yesterday:
            return .yesterday(timezone: timezone)
        case .lastWeek:
            return .lastWeek(timezone: timezone)
        case .lastMonth:
            return .lastMonth(timezone: timezone)
        case .weekToDate:
            return .weekToDate(timezone: timezone)
        case .monthToDate:
            return .monthToDate(timezone: timezone)
        }
    }
}
