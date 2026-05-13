import AppIntents

/// Date ranges supported by the Store Stats widget.
/// ("today / last 7 days / last 30 days") called out in the project's M1 scope.
///
enum StoreStatsWidgetDateRange: String, AppEnum {
    case today
    case last7Days
    case last30Days

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Date Range")
    }

    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .today: "Today",
        .last7Days: "Last 7 Days",
        .last30Days: "Last 30 Days"
    ]
}
