import AppIntents
import WidgetKit

/// Configuration intent for the Store Stats widget.
///
/// Surfaces the user-facing widget settings (long-press → Edit Widget).
///
struct StoreStatsConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Store Stats"
    static var description = IntentDescription("Choose how the WooCommerce stats widget is displayed.")

    @Parameter(title: "Store")
    var store: StoreStatsStoreEntity?

    @Parameter(title: "Date Range", default: .today)
    var dateRange: StoreStatsWidgetDateRange

    /// User-selected metric set, in display order.
    ///
    /// The `size:` map drives iOS's family-aware fixed-slot rendering — small shows 2 inline
    /// rows, medium 4, large 7. The picker shows the full catalog; metrics whose data isn't
    /// available for the user's auth mode (`visitors`, `conversion` on self-hosted) render
    /// with the standard "-" placeholder in the cell.
    ///
    /// The default lists all 7 catalog metrics in priority order so iOS persists enough state
    /// to cover the largest family on first install. After a resize-up,
    /// `StoreInfoProvider.resolveMetricSelection` tops up undersized arrays from the same
    /// priority order so the widget body renders identically to a fresh install at the new
    /// family.
    ///
    @Parameter(
        title: "Metrics",
        default: [
            .revenue, .orders, .itemsSold, .averageOrderValue,
            .netSales, .visitors, .conversion
        ],
        size: [
            .systemSmall: .init(exactly: 2),
            .systemMedium: .init(exactly: 4),
            .systemLarge: .init(exactly: 7)
        ],
        query: AvailableMetricsQuery()
    )
    var metrics: [StoreInfoMetricType]

    init() {
        store = StoreStatsStoreEntity.defaultStore
    }
}

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

struct StoreStatsStoreEntity: AppEntity, Hashable {
    private static let defaultStoreID = "__default_store__"
    static let defaultStore = StoreStatsStoreEntity(id: defaultStoreID, name: nil)

    static var defaultQuery = StoreStatsStoreQuery()

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Store")
    }

    let id: String
    let name: String?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayName)")
    }

    init(snapshot: StoreStatsSnapshot) {
        id = snapshot.appEntityID
        name = snapshot.name
    }

    init(id: String, name: String?) {
        self.id = id
        self.name = name
    }

    static func isDefaultStoreID(_ id: String) -> Bool {
        id == defaultStoreID
    }

    private var displayName: String {
        if Self.isDefaultStoreID(id),
           let defaultStoreName = StoreStatsSnapshotStore().defaultStoreName() {
            return defaultStoreName
        }
        return name ?? "Store"
    }
}

struct StoreStatsStoreQuery: EntityQuery {
    func entities(for identifiers: [StoreStatsStoreEntity.ID]) async throws -> [StoreStatsStoreEntity] {
        let identifiers = Set(identifiers)
        let entities = StoreStatsSnapshotStore().storePickerSnapshots()
            .filter { identifiers.contains($0.appEntityID) }
            .map(StoreStatsStoreEntity.init(snapshot:))
        guard identifiers.contains(where: StoreStatsStoreEntity.isDefaultStoreID) else {
            return entities
        }
        return [StoreStatsStoreEntity.defaultStore] + entities
    }

    func suggestedEntities() async throws -> [StoreStatsStoreEntity] {
        StoreStatsSnapshotStore().storePickerSnapshots().map(StoreStatsStoreEntity.init(snapshot:))
    }

    func defaultResult() async -> StoreStatsStoreEntity? {
        StoreStatsStoreEntity.defaultStore
    }
}
