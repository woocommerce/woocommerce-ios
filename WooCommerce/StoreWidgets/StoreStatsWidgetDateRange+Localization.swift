extension StoreStatsWidgetDateRange {
    /// Localized label rendered inside the widget body. Kept separate from
    /// `caseDisplayRepresentations` because intent UI strings live in the widget extension's
    /// own bundle, while the in-widget body reads strings from the host app via `AppLocalizedString`.
    var localizedRangeLabel: String {
        switch self {
        case .today:
            return AppLocalizedString(
                "storeWidgets.dateRange.today",
                value: "Today",
                comment: "Range label for the Today option in the Store Stats widget"
            )
        case .yesterday:
            return AppLocalizedString(
                "storeWidgets.dateRange.yesterday",
                value: "Yesterday",
                comment: "Range label for the Yesterday option in the Store Stats widget"
            )
        case .lastWeek:
            return AppLocalizedString(
                "storeWidgets.dateRange.lastWeek",
                value: "Last Week",
                comment: "Range label for the Last Week option in the Store Stats widget"
            )
        case .lastMonth:
            return AppLocalizedString(
                "storeWidgets.dateRange.lastMonth",
                value: "Last Month",
                comment: "Range label for the Last Month option in the Store Stats widget"
            )
        case .weekToDate:
            return AppLocalizedString(
                "storeWidgets.dateRange.weekToDate",
                value: "Week to Date",
                comment: "Range label for the Week to Date option in the Store Stats widget"
            )
        case .monthToDate:
            return AppLocalizedString(
                "storeWidgets.dateRange.monthToDate",
                value: "Month to Date",
                comment: "Range label for the Month to Date option in the Store Stats widget"
            )
        }
    }

    /// Compact label for constrained lock-screen surfaces.
    var localizedCompactRangeLabel: String {
        switch self {
        case .today:
            return AppLocalizedString(
                "storeWidgets.dateRange.todayCompact",
                value: "1d",
                comment: "Compact range label for the Today option in the Store Stats lock-screen widget"
            )
        case .last7Days:
            return AppLocalizedString(
                "storeWidgets.dateRange.last7DaysCompact",
                value: "7d",
                comment: "Compact range label for the Last 7 Days option in the Store Stats lock-screen widget"
            )
        case .last30Days:
            return AppLocalizedString(
                "storeWidgets.dateRange.last30DaysCompact",
                value: "30d",
                comment: "Compact range label for the Last 30 Days option in the Store Stats lock-screen widget"
            )
        }
    }
}
