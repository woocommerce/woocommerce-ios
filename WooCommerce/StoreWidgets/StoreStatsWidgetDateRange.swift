import AppIntents

/// Raw values mirror `AnalyticsHubTimeRangeSelection.SelectionType` so they round-trip
/// through the per-cell deep-link URL into the in-app Analytics Hub.
enum StoreStatsWidgetDateRange: String, AppEnum {
    case today
    case yesterday
    case lastWeek
    case lastMonth
    case weekToDate
    case monthToDate

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Date Range")
    }

    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .today: "Today",
        .yesterday: "Yesterday",
        .lastWeek: "Last Week",
        .lastMonth: "Last Month",
        .weekToDate: "Week to Date",
        .monthToDate: "Month to Date"
    ]
}
