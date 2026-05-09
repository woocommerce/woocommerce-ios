import AppIntents
import WidgetKit

/// Configuration intent for the Store Stats widget.
///
/// Surfaces the user-facing widget settings (long-press → Edit Widget).
///
struct StoreStatsConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Store Stats"
    static var description = IntentDescription("Choose how the WooCommerce stats widget is displayed.")

    static let defaultDateRange: StoreStatsWidgetDateRange = .today

    static let defaultMetrics: [StoreInfoMetricType] = [
        .revenue, .orders, .itemsSold, .averageOrderValue,
        .netSales, .visitors, .conversion
    ]

    static let metricsSlotCounts: [WidgetFamily: Int] = [
        .systemSmall: 2,
        .systemMedium: 4,
        .systemLarge: 7
    ]

    @Parameter(title: "Store")
    var store: StoreStatsStoreEntity?

    @Parameter(title: "Date Range", default: .today)
    var dateRange: StoreStatsWidgetDateRange

    /// User-selected metric set, in display order.
    ///
    /// The `size:` map drives iOS's family-aware fixed-slot rendering — small shows 2 metrics,
    /// medium 4, and large 7. The picker shows the full catalog; metrics whose data isn't
    /// available for the user's auth mode (`visitors`, `conversion` on self-hosted) render
    /// with the standard "-" placeholder in the cell.
    ///
    /// The default lists the full catalog in priority order so iOS persists enough state
    /// to cover the largest family and available choices on first install. After a resize-up,
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
            .systemLarge: .init(exactly: 7),
        ],
        query: AvailableMetricsQuery()
    )
    var metrics: [StoreInfoMetricType]

    init() {
        store = StoreStatsStoreEntity.defaultStore
    }
}

enum StoreStatsStoreSelection {
    static let defaultStoreEntityID = "__default_store__"

    static func isDefaultStoreEntityID(_ id: String) -> Bool {
        id == defaultStoreEntityID
    }

    static func entityID(for siteID: Int64) -> String {
        String(siteID)
    }
}

struct StoreStatsStoreEntity: AppEntity, Hashable {
    static let defaultStore = StoreStatsStoreEntity(id: StoreStatsStoreSelection.defaultStoreEntityID, name: nil)

    static var defaultQuery = StoreStatsStoreQuery()

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Store")
    }

    let id: String
    let name: String?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayName)")
    }

    init(site: WidgetSite) {
        id = StoreStatsStoreSelection.entityID(for: site.siteID)
        name = site.name
    }

    init(id: String, name: String?) {
        self.id = id
        self.name = name
    }

    static func isDefaultStoreID(_ id: String) -> Bool {
        StoreStatsStoreSelection.isDefaultStoreEntityID(id)
    }

    private var displayName: String {
        if Self.isDefaultStoreID(id),
           let defaultStoreName = UserDefaults.group?[.defaultStoreName] as? String {
            return defaultStoreName
        }
        return name ?? "Store"
    }
}

struct StoreStatsStoreQuery: EntityQuery {
    private let siteListStore: WidgetSiteListStore

    init() {
        self.init(siteListStore: WidgetSiteListStore())
    }

    init(siteListStore: WidgetSiteListStore = WidgetSiteListStore()) {
        self.siteListStore = siteListStore
    }

    func entities(for identifiers: [StoreStatsStoreEntity.ID]) async throws -> [StoreStatsStoreEntity] {
        let identifiers = Set(identifiers)
        let entities = siteListStore.sites()
            .filter { identifiers.contains(StoreStatsStoreSelection.entityID(for: $0.siteID)) }
            .map(StoreStatsStoreEntity.init(site:))

        guard identifiers.contains(where: StoreStatsStoreEntity.isDefaultStoreID) else {
            return entities
        }
        return [StoreStatsStoreEntity.defaultStore] + entities
    }

    func suggestedEntities() async throws -> [StoreStatsStoreEntity] {
        siteListStore.sites().map(StoreStatsStoreEntity.init(site:))
    }

    func defaultResult() async -> StoreStatsStoreEntity? {
        StoreStatsStoreEntity.defaultStore
    }
}
