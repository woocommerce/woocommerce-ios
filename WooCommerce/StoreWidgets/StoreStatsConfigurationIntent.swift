import AppIntents
import WidgetKit

/// Configuration intent for the Store Stats widget.
///
/// Surfaces the user-facing widget settings (long-press → Edit Widget). Subsequent tickets
/// add `@Parameter` declarations (metrics, store picker) on top of the date range here.
///
struct StoreStatsConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Store Stats"
    static var description = IntentDescription("Choose how the WooCommerce stats widget is displayed.")

    @Parameter(title: "Date Range", default: .today)
    var dateRange: StoreStatsWidgetDateRange
}

/// Date ranges supported by the Store Stats widget. Mirrors the Shopify reference set
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
