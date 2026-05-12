import Foundation

extension StoreStatsWidgetDateRange {
    /// Maps the user-selected widget range using the selected store's timezone.
    ///
    func serviceDateRange(timezone: TimeZone = .current) -> StoreInfoDataService.DateRange {
        switch self {
        case .today:
            return .today(timezone: timezone)
        case .last7Days:
            return .last7Days(timezone: timezone)
        case .last30Days:
            return .last30Days(timezone: timezone)
        }
    }
}
