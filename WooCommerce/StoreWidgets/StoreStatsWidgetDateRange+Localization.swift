extension StoreStatsWidgetDateRange {
    /// Localized label rendered inside the widget body (top-right of the medium home-screen
    /// widget). Kept separate from `caseDisplayRepresentations` because intent UI strings live
    /// in the widget extension's own bundle, while the in-widget body reads strings from the
    /// host app bundle via `AppLocalizedString`.
    ///
    var localizedRangeLabel: String {
        switch self {
        case .today:
            return AppLocalizedString(
                "storeWidgets.dateRange.today",
                value: "Today",
                comment: "Range label for the Today option in the Store Stats widget"
            )
        case .last7Days:
            return AppLocalizedString(
                "storeWidgets.dateRange.last7Days",
                value: "Last 7 Days",
                comment: "Range label for the Last 7 Days option in the Store Stats widget"
            )
        case .last30Days:
            return AppLocalizedString(
                "storeWidgets.dateRange.last30Days",
                value: "Last 30 Days",
                comment: "Range label for the Last 30 Days option in the Store Stats widget"
            )
        }
    }
}
