import WidgetKit
import WooFoundation
import KeychainAccess
import Networking

/// Type that represents the all the possible Widget states.
///
enum StoreInfoEntry: TimelineEntry {
    // Represents a not logged-in state
    case notConnected

    // Represents a fetching error state
    case error

    // Represents a fetched data state
    case data(StoreInfoData)

    // Current date, needed by the `TimelineEntry` protocol.
    var date: Date { Date() }
}

/// Type that represents the the widget state data.
///
/// Field shape matches trunk so the legacy `StoreInfoView` / `StatsCard` and the lock-screen
/// widgets keep building unchanged. The metric catalog (`metrics`) is defaulted so callers
/// that only need the legacy String fields don't have to populate it. The main provider
/// populates both shapes; view selection is controlled by `useMetricsHomescreenWidget`.
///
struct StoreInfoData {
    /// Eg: Today, Weekly, Monthly, Yearly
    ///
    var range: String

    /// Store name
    ///
    var name: String

    /// Revenue at the range (eg: today)
    ///
    var revenue: String

    /// Revenue at the range (eg: today) in compact format (eg: $12k)
    ///
    var revenueCompact: String

    /// Visitors count at the range (eg: today)
    ///
    var visitors: String

    /// Order count at the range (eg: today)
    ///
    var orders: String

    /// Conversion at the range (eg: today)
    ///
    var conversion: String

    /// Time when the widget was last refreshed (eg: 10.24PM)
    ///
    var updatedTime: String

    /// Slot-preserving metric entries for the metric-driven widget path. Explicit "None"
    /// selections become `.empty` so the UI can keep the configured position blank.
    ///
    var metricSlots: [StoreInfoMetricSlot]

    /// Concrete metric entries, derived from `metricSlots` for legacy readers and analytics
    /// that should ignore explicit empty slots.
    ///
    var metrics: [StoreInfoMetric] {
        metricSlots.compactMap(\.concreteMetric)
    }

    init(range: String,
         name: String,
         revenue: String,
         revenueCompact: String,
         visitors: String,
         orders: String,
         conversion: String,
         updatedTime: String,
         metrics: [StoreInfoMetric] = [],
         metricSlots: [StoreInfoMetricSlot]? = nil,
         dateRange: StoreStatsWidgetDateRange? = nil) {
        self.range = range
        self.name = name
        self.revenue = revenue
        self.revenueCompact = revenueCompact
        self.visitors = visitors
        self.orders = orders
        self.conversion = conversion
        self.updatedTime = updatedTime
        self.metricSlots = metricSlots ?? metrics.map { .metric($0) }
        self.dateRange = dateRange
    }

    /// Used to build per-cell deep-link URLs. `nil` for surfaces without a configured range
    /// (placeholder previews) — those render without deep-link affordance.
    var dateRange: StoreStatsWidgetDateRange? = nil
}

extension StoreInfoData {
    /// Returns the entry for the given metric type, or an `.unavailable` placeholder
    /// if the metric isn't present in the current data set.
    ///
    /// A miss is treated as a wiring bug (provider didn't include an expected metric);
    /// `assertionFailure` catches it in debug, while production falls through to the
    /// placeholder so the widget still renders as `-` instead of crashing.
    ///
    func metric(of type: StoreInfoMetricType) -> StoreInfoMetric {
        if let metric = metrics.first(where: { $0.type == type }) {
            return metric
        }
        assertionFailure("StoreInfoData missing expected metric: \(type.rawValue)")
        return StoreInfoMetric(type: type, value: .unavailable)
    }

    /// Wraps each metric in a `WidgetMetricPresenter` paired with the configured date range.
    var presentableMetrics: [any MetricPresentable] {
        metrics.map { WidgetMetricPresenter(metric: $0, dateRange: dateRange) }
    }
}

/// Type that provides data entries to the widget system.
///
/// Backs both the legacy `StaticConfiguration` path (via `TimelineProvider` here) and the
/// `AppIntentConfiguration` path (via `AppIntentTimelineProvider` conformance in
/// `StoreInfoProvider+AppIntentTimelineProvider.swift`). Sharing one provider keeps the
/// data-fetching logic in a single place while the configurable widget rolls out behind
/// `FeatureFlag.configurableStoreStatsWidgets`.
///
final class StoreInfoProvider: TimelineProvider {

    /// Desired data reload interval provided to system = 30 minutes.
    ///
    private let reloadInterval: TimeInterval = 30 * 60

    /// Redacted entry with sample data.
    ///
    func placeholder(in context: Context) -> StoreInfoEntry {
        Self.placeholderEntry(
            for: Self.fetchDependencies(),
            metrics: Self.resolveMetricSelection(
                requested: StoreStatsConfigurationIntent.defaultMetrics,
                family: context.family
            )
        )
    }

    func placeholder(for configuration: StoreStatsConfigurationIntent, in context: Context) -> StoreInfoEntry {
        Self.placeholderEntry(
            for: Self.fetchDependencies(),
            dateRange: configuration.dateRange,
            metrics: Self.resolveMetricSelection(
                requested: configuration.metrics,
                family: context.family
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (StoreInfoEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StoreInfoEntry>) -> Void) {
        Task {
            // Legacy `StaticConfiguration` path. Hardcoded today range + 4-cell preset, bypassing
            // the AppIntent metric resolver on purpose — the configurable behavior belongs to
            // the `AppIntentConfiguration` branch only.
            let timeline = await loadTimeline(dateRange: .today, metrics: Self.legacyMetricsPreset)
            completion(timeline)
        }
    }

    /// Shared loader for both `TimelineProvider` and `AppIntentTimelineProvider` paths.
    /// Visible to extensions in this module so the AppIntent conformance can share logic.
    ///
    /// The legacy path passes `legacyMetricsPreset`; the AppIntent path passes the resolved
    /// user selection from `resolveMetricSelection`.
    ///
    func loadTimeline(
        dateRange: StoreStatsWidgetDateRange,
        metrics: [StoreInfoMetricType],
        selectedStoreID: StoreStatsStoreEntity.ID? = nil
    ) async -> Timeline<StoreInfoEntry> {
        guard let dependencies = Self.fetchDependencies(selectedStoreID: selectedStoreID) else {
            return Timeline<StoreInfoEntry>(entries: [.notConnected], policy: .never)
        }

        let reloadDate = Date(timeIntervalSinceNow: reloadInterval)
        let service = StoreInfoDataService(credentials: dependencies.credentials)
        do {
            async let statsPeriodRequest = service.fetchStats(
                for: dependencies.store.storeID,
                dateRange: dateRange.serviceDateRange(timezone: dependencies.store.storeTimeZone)
            )
            async let storeRequest = Self.refreshedStoreMetadata(dependencies.store, service: service)
            let statsPeriod = try await statsPeriodRequest
            let store = await storeRequest
            let updatedDependencies = Dependencies(credentials: dependencies.credentials, store: store)
            let entry = Self.dataEntry(
                for: statsPeriod,
                dateRange: dateRange,
                with: updatedDependencies,
                metrics: metrics
            )
            return Timeline<StoreInfoEntry>(entries: [entry], policy: .after(reloadDate))
        } catch {
            // WooFoundation does not expose `DDLOG` types. Should we include them?
            print("⛔️ Error fetching today's widget stats: \(error)")
            return Timeline<StoreInfoEntry>(entries: [.error], policy: .after(reloadDate))
        }
    }

    static func refreshedStoreMetadata(_ store: StoreMetadata,
                                       service: StoreInfoDataService,
                                       currencyCache: WidgetSiteCurrencyCache = WidgetSiteCurrencyCache()) async -> StoreMetadata {
        guard let siteID = store.siteIDNeedingCurrencySettingsRefresh else {
            return store
        }

        do {
            let currencySettings = try await service.fetchGeneralSettings(siteID: siteID)
            currencyCache.save(currencySettings, forSiteID: siteID)
            return store.replacingCurrencySettings(currencySettings)
        } catch {
            print("⛔️ Error fetching widget currency settings: \(error)")
            return store
        }
    }
}

// MARK: - Metric presets & resolution

extension StoreInfoProvider {
    /// Hardcoded preset used by the legacy `StaticConfiguration` path (`getTimeline`) and as the
    /// fallback placeholder selection. Matches the original 4-cell shape — non-WPCom users see
    /// `visitors` / `conversion` as `.unavailable`. Real AppIntent timelines and snapshots
    /// derive their selection from the user's stored configuration.
    ///
    static let legacyMetricsPreset: [StoreInfoMetricType] = [
        .revenue, .visitors, .orders, .conversion
    ]
}

extension StoreInfoProvider {
    /// Catalog priority order. Mirrors the parameter `default:` in `StoreStatsConfigurationIntent`
    /// so the render-time top-up draws from the same list iOS hands out at first install — a
    /// resize-up tile renders identically to a fresh install at the new family.
    ///
    private static let catalogPriorityOrder = StoreInfoMetricType.catalogCases

    /// Family slot counts that the home-screen view caps at when rendering. Mirrors the `size:`
    /// map on the intent's `metrics` parameter. Lock-screen families return `nil` — they ignore
    /// `StoreInfoData.metrics` and read fixed fields off `StoreInfoData` directly.
    ///
    private static func homescreenSlotCount(_ family: WidgetFamily) -> Int? {
        switch family {
        case .systemSmall: return 2
        case .systemMedium: return 4
        case .systemLarge: return 7
        default: return nil
        }
    }

    /// Maps the user's requested metric set onto what the configurable widget can render.
    /// **AppIntent path only** — the legacy `StaticConfiguration` path bypasses this entirely
    /// and uses `legacyMetricsPreset`.
    ///
    /// iOS persists the user's selection per tile and does not auto-extend the array when a
    /// tile resizes to a larger family — `EntityQuery` has no default-fill hook to participate
    /// in that. To keep the widget body looking complete after a resize-up, this resolver:
    ///
    /// 1. Slices oversized arrays (resize-down) to the family's slot count.
    /// 2. Tops up undersized arrays from `catalogPriorityOrder` until full, deduping concrete
    ///    metrics. Explicit `.none` selections count as occupied slots and are not replaced.
    ///    The auto-fill order matches the parameter `default:` so resize-up content is
    ///    predictable and identical to a fresh install at the new family.
    ///
    /// Trade-off: the Edit Widget UI is iOS-controlled and shows "Choose" placeholders for
    /// slots that don't have an explicit user pick — even though the widget body has rendered
    /// content there. Apple owns the Edit Widget UI; we can't surface our top-up there.
    ///
    static func resolveMetricSelection(
        requested: [StoreInfoMetricType],
        family: WidgetFamily
    ) -> [StoreInfoMetricType] {
        guard let target = homescreenSlotCount(family) else {
            return requested
        }

        if requested.count > target {
            return Array(requested.prefix(target))
        }

        var resolved = requested
        for fallback in catalogPriorityOrder where resolved.count < target {
            guard !resolved.contains(fallback) else { continue }
            resolved.append(fallback)
        }
        return resolved
    }
}

private extension StoreInfoDataService.Stats {
    /// Maps a catalog metric type to the corresponding resolved value off this stats snapshot.
    /// Currency-typed metrics carry the store's `CurrencySettings`; metrics whose data the
    /// service couldn't fetch (`visitors` / `conversion` for self-hosted, network-degraded WPCom
    /// fall-back) fall through to `.unavailable`.
    ///
    func value(for metric: StoreInfoMetricType, currencySettings: CurrencySettings) -> StoreInfoMetricValue {
        switch metric {
        case .none:
            return .unavailable
        case .revenue:
            return .currency(revenue, currencySettings)
        case .netSales:
            return .currency(netRevenue, currencySettings)
        case .averageOrderValue:
            return .currency(averageOrderValue, currencySettings)
        case .orders:
            return .count(totalOrders)
        case .itemsSold:
            return .count(totalItemsSold)
        case .visitors:
            return totalVisitors.map { .count($0) } ?? .unavailable
        case .conversion:
            return conversion.map { .percentage($0) } ?? .unavailable
        }
    }

    /// Projects the typed series properties into the cell's presentation type.
    func chartSeries(for metric: StoreInfoMetricType) -> [MetricChartPoint]? {
        let points: [IntervalPoint]
        switch metric {
        case .none: return nil
        case .revenue: points = revenueSeries
        case .netSales: points = netRevenueSeries
        case .averageOrderValue: points = averageOrderValueSeries
        case .orders: points = ordersSeries
        case .itemsSold: points = itemsSoldSeries
        case .visitors, .conversion: return nil
        }
        guard points.count > 1 else { return nil }
        return points.map { MetricChartPoint(date: $0.date, value: $0.value) }
    }
}

extension StoreInfoProvider {

    /// Dependencies needed by the `StoreInfoProvider`
    ///
    struct Dependencies {
        let credentials: Credentials
        let store: StoreMetadata
    }

    struct StoreMetadata {
        let storeID: Int64
        let storeName: String
        let storeCurrencySettings: CurrencySettings
        let storeTimeZone: TimeZone
        let siteIDNeedingCurrencySettingsRefresh: Int64?

        func replacingCurrencySettings(_ currencySettings: CurrencySettings) -> StoreMetadata {
            StoreMetadata(storeID: storeID,
                          storeName: storeName,
                          storeCurrencySettings: currencySettings,
                          storeTimeZone: storeTimeZone,
                          siteIDNeedingCurrencySettingsRefresh: nil)
        }
    }

    /// Fetches the required dependencies from the keychain and the shared users default.
    ///
    static func fetchDependencies(selectedStoreID: StoreStatsStoreEntity.ID? = nil) -> Dependencies? {
        let keychain = Keychain(service: WooConstants.keychainServiceName)
        let credentials: Credentials? = {
            if let authToken = keychain[WooConstants.authToken] {
                return Credentials(authToken: authToken)
            } else if let username = UserDefaults.group?[.defaultUsername] as? String,
                      let password = keychain[WooConstants.siteCredentialPassword],
                      let siteAddress = UserDefaults.group?[.defaultSiteAddress] as? String {
                return .wporg(username: username, password: password, siteAddress: siteAddress)
            } else if let username = UserDefaults.group?[.defaultUsername] as? String,
                      let password = keychain[WooConstants.applicationPassword],
                      let siteAddress = UserDefaults.group?[.defaultSiteAddress] as? String {
                return .applicationPassword(username: username, password: password, siteAddress: siteAddress)
            }
            return nil
        }()
        guard let credentials else {
            print("⛔️ missing credentials")
            return nil
        }

        let sites = WidgetSiteListStore().sites()

        guard let defaultStore = defaultStoreMetadata(sites: sites) else {
            print("⛔️ missing store info")
            return nil
        }

        let selectedStore = selectedStoreMetadata(defaultStore: defaultStore,
                                                  selectedStoreID: selectedStoreID,
                                                  sites: sites)
        return Dependencies(credentials: credentials,
                            store: selectedStore)
    }

    static func selectedStoreMetadata(defaultStore: StoreMetadata,
                                      selectedStoreID: StoreStatsStoreEntity.ID?,
                                      sites: [WidgetSite],
                                      currencyCache: WidgetSiteCurrencyCache = WidgetSiteCurrencyCache()) -> StoreMetadata {
        guard let selectedStoreID,
              StoreStatsStoreSelection.isDefaultStoreEntityID(selectedStoreID) == false,
              let selectedSiteID = Int64(selectedStoreID),
              let selectedSite = sites.first(where: { $0.siteID == selectedSiteID }) else {
            return defaultStore
        }

        let currencyResult: (settings: CurrencySettings, siteIDNeedingRefresh: Int64?) = {
            guard selectedSite.siteID != defaultStore.storeID else {
                return (defaultStore.storeCurrencySettings, nil)
            }

            if let currencySettings = selectedSite.currencySettings {
                return (currencySettings, nil)
            }

            if let currencySettings = currencyCache.currencySettings(forSiteID: selectedSite.siteID) {
                return (currencySettings, nil)
            }

            return (defaultStore.storeCurrencySettings, selectedSite.siteID)
        }()

        return StoreMetadata(storeID: selectedSite.siteID,
                             storeName: selectedSite.name,
                             storeCurrencySettings: currencyResult.settings,
                             storeTimeZone: selectedSite.timezone,
                             siteIDNeedingCurrencySettingsRefresh: currencyResult.siteIDNeedingRefresh)
    }

    static func defaultStoreMetadata(sites: [WidgetSite]) -> StoreMetadata? {
        guard let storeID = UserDefaults.group?[.defaultStoreID] as? Int64,
              let storeName = UserDefaults.group?[.defaultStoreName] as? String,
              let storeCurrencySettingsData = UserDefaults.group?[.defaultStoreCurrencySettings] as? Data,
              let storeCurrencySettings = try? JSONDecoder().decode(CurrencySettings.self, from: storeCurrencySettingsData) else {
            return nil
        }

        return StoreMetadata(storeID: storeID,
                             storeName: storeName,
                             storeCurrencySettings: storeCurrencySettings,
                             storeTimeZone: sites.first(where: { $0.siteID == storeID })?.timezone ?? .current,
                             siteIDNeedingCurrencySettingsRefresh: nil)
    }
}

/// Data configuration
///
private extension StoreInfoProvider {

    /// Redacted entry with sample data. If dependencies are available — store name and currency
    /// settings will be used. Both the legacy String fields and the metric-driven slots derive
    /// from `Stats.placeholderSample`, while the metric selection mirrors the family-specific
    /// AppIntent defaults so the widget gallery renders a complete preview with trends and
    /// charts.
    ///
    static func placeholderEntry(
        for dependencies: Dependencies?,
        dateRange: StoreStatsWidgetDateRange = .today,
        metrics: [StoreInfoMetricType] = legacyMetricsPreset
    ) -> StoreInfoEntry {
        let currencySettings = dependencies?.store.storeCurrencySettings ?? CurrencySettings()
        let sample = StoreInfoDataService.Stats.placeholderSample
        let previousSample = StoreInfoDataService.Stats.placeholderPreviousSample
        let metricSlots: [StoreInfoMetricSlot] = metrics.map { type in
            guard type != .none else {
                return .empty
            }

            return .metric(StoreInfoMetric(
                type: type,
                value: sample.value(for: type, currencySettings: currencySettings),
                previousValue: previousSample.value(for: type, currencySettings: currencySettings),
                chartSeries: sample.chartSeries(for: type)
            ))
        }
        let visitorsString = sample.totalVisitors.map(String.init) ?? StoreInfoFormatter.Constants.valuePlaceholderText
        let conversionString = sample.conversion.map(StoreInfoFormatter.formattedConversionString) ?? StoreInfoFormatter.Constants.valuePlaceholderText
        return .data(.init(
            range: dateRange.localizedRangeLabel,
            name: dependencies?.store.storeName ?? Localization.myShop,
            revenue: StoreInfoFormatter.formattedAmountString(for: sample.revenue, with: currencySettings),
            revenueCompact: StoreInfoFormatter.formattedAmountCompactString(for: sample.revenue, with: currencySettings),
            visitors: visitorsString,
            orders: "\(sample.totalOrders)",
            conversion: conversionString,
            updatedTime: StoreInfoFormatter.currentFormattedTime(),
            metricSlots: metricSlots
        ))
    }

    /// Real data entry. `metrics` is the resolved selection — already family-sliced and topped
    /// up by `resolveMetricSelection` for the AppIntent path, or the legacy hardcoded preset for
    /// the `StaticConfiguration` path. Ordering here is what the home-screen view renders,
    /// including explicit `.none` entries that preserve empty slots.
    ///
    /// Each `StoreInfoMetric` carries both the current and the previous-period value so the
    /// metric-driven home-screen view can render trend badges. The legacy String fields below
    /// only reflect the current period.
    ///
    static func dataEntry(for statsPeriod: StoreInfoDataService.StatsPeriod,
                          dateRange: StoreStatsWidgetDateRange,
                          with dependencies: Dependencies,
                          metrics: [StoreInfoMetricType]) -> StoreInfoEntry {
        let currencySettings = dependencies.store.storeCurrencySettings
        let stats = statsPeriod.current
        let previousStats = statsPeriod.previous
        let metricSlots: [StoreInfoMetricSlot] = metrics.map { type in
            guard type != .none else {
                return .empty
            }

            return .metric(StoreInfoMetric(
                type: type,
                value: stats.value(for: type, currencySettings: currencySettings),
                previousValue: previousStats?.value(for: type, currencySettings: currencySettings),
                chartSeries: stats.chartSeries(for: type)
            ))
        }
        let visitorsString: String = {
            if let visitors = stats.totalVisitors {
                return "\(visitors)"
            }
            return StoreInfoFormatter.Constants.valuePlaceholderText
        }()
        let conversionString: String = {
            if let conversion = stats.conversion {
                return StoreInfoFormatter.formattedConversionString(for: conversion)
            }
            return StoreInfoFormatter.Constants.valuePlaceholderText
        }()

        return .data(.init(
            range: dateRange.localizedRangeLabel,
            name: dependencies.store.storeName,
            revenue: StoreInfoFormatter.formattedAmountString(for: stats.revenue, with: currencySettings),
            revenueCompact: StoreInfoFormatter.formattedAmountCompactString(for: stats.revenue, with: currencySettings),
            visitors: visitorsString,
            orders: "\(stats.totalOrders)",
            conversion: conversionString,
            updatedTime: StoreInfoFormatter.currentFormattedTime(),
            metricSlots: metricSlots,
            dateRange: dateRange
        ))
    }

    enum Localization {
        static let myShop = AppLocalizedString(
            "storeWidgets.infoProvider.myShop",
            value: "My Shop",
            comment: "Generic store name for the store info widget preview"
        )
    }
}
