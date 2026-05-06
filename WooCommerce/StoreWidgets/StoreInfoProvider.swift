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

    /// Resolved metric entries for the new metric-catalog driven path. Ordering here is
    /// the source of truth; metric-driven views render entries in this order. Currency-typed
    /// metrics carry their own `CurrencySettings`, so this struct doesn't need a global one.
    ///
    var metrics: [StoreInfoMetric] = []
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
        let dependencies = Self.fetchDependencies()
        return Self.placeholderEntry(for: dependencies)
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
            let statsPeriod = try await service.fetchStats(
                for: dependencies.storeID,
                dateRange: dateRange.serviceDateRange(timezone: dependencies.storeTimeZone),
                supportsVisitorStats: dependencies.supportsVisitorStats
            )
            let entry = Self.dataEntry(
                for: statsPeriod,
                dateRange: dateRange,
                with: dependencies,
                metrics: metrics
            )
            return Timeline<StoreInfoEntry>(entries: [entry], policy: .after(reloadDate))
        } catch {
            // WooFoundation does not expose `DDLOG` types. Should we include them?
            print("⛔️ Error fetching today's widget stats: \(error)")
            return Timeline<StoreInfoEntry>(entries: [.error], policy: .after(reloadDate))
        }
    }
}

// MARK: - Metric presets & resolution

extension StoreInfoProvider {
    /// Hardcoded preset used by the legacy `StaticConfiguration` path (`getTimeline`) and by
    /// `placeholderEntry`. Matches the original 4-cell shape — non-WPCom users see `visitors` /
    /// `conversion` as `.unavailable`. Not consumed by the AppIntent path; the configurable
    /// branch derives its own selection from the user's stored configuration.
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
    private static let catalogPriorityOrder: [StoreInfoMetricType] = [
        .revenue, .orders, .itemsSold, .averageOrderValue,
        .netSales, .visitors, .conversion
    ]

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
    /// 2. Tops up undersized arrays from `catalogPriorityOrder` until full, deduping. The
    ///    auto-fill order matches the parameter `default:` so resize-up content is predictable
    ///    and identical to a fresh install at the new family.
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
}

private extension StoreInfoProvider {

    /// Dependencies needed by the `StoreInfoProvider`
    ///
    struct Dependencies {
        let credentials: Credentials
        let storeID: Int64
        let storeName: String
        let storeCurrencySettings: CurrencySettings
        let storeTimeZone: TimeZone
        let supportsVisitorStats: Bool
    }

    struct StoreMetadata {
        let storeID: Int64
        let storeName: String
        let storeCurrencySettings: CurrencySettings
        let storeTimeZone: TimeZone
        let supportsVisitorStats: Bool
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

        guard let defaultStore = defaultStoreMetadata() else {
            print("⛔️ missing store info")
            return nil
        }

        let defaultDependencies = Dependencies(credentials: credentials,
                                               storeID: defaultStore.storeID,
                                               storeName: defaultStore.storeName,
                                               storeCurrencySettings: defaultStore.storeCurrencySettings,
                                               storeTimeZone: defaultStore.storeTimeZone,
                                               supportsVisitorStats: defaultStore.supportsVisitorStats)
        let snapshots = StoreStatsSnapshotStore().snapshots()
        guard let selectedStore = selectedStoreSnapshot(from: snapshots,
                                                        selectedStoreID: selectedStoreID,
                                                        defaultStoreID: defaultStore.storeID) else {
            return defaultDependencies
        }

        let storeCurrencySettings = currencySettings(for: selectedStore,
                                                     defaultStoreID: defaultStore.storeID,
                                                     defaultCurrencySettings: defaultStore.storeCurrencySettings)
        return Dependencies(credentials: credentials,
                            storeID: selectedStore.siteID,
                            storeName: selectedStore.name,
                            storeCurrencySettings: storeCurrencySettings,
                            storeTimeZone: selectedStore.timeZone,
                            supportsVisitorStats: selectedStore.supportsVisitorStats)
    }

    static func defaultStoreMetadata() -> StoreMetadata? {
        guard let storeID = UserDefaults.group?[.defaultStoreID] as? Int64,
              let storeName = UserDefaults.group?[.defaultStoreName] as? String,
              let storeCurrencySettingsData = UserDefaults.group?[.defaultStoreCurrencySettings] as? Data,
              let storeCurrencySettings = try? JSONDecoder().decode(CurrencySettings.self, from: storeCurrencySettingsData) else {
            return nil
        }

        return StoreMetadata(storeID: storeID,
                             storeName: storeName,
                             storeCurrencySettings: storeCurrencySettings,
                             storeTimeZone: .current,
                             supportsVisitorStats: true)
    }
}

extension StoreInfoProvider {
    static func currencySettings(for selectedStore: StoreStatsSnapshot,
                                 defaultStoreID: Int64,
                                 defaultCurrencySettings: CurrencySettings) -> CurrencySettings {
        guard selectedStore.siteID != defaultStoreID else {
            return defaultCurrencySettings
        }
        return selectedStore.currencySettings ?? defaultCurrencySettings
    }

    static func selectedStoreSnapshot(from snapshots: [StoreStatsSnapshot],
                                      selectedStoreID: StoreStatsStoreEntity.ID?,
                                      defaultStoreID: Int64? = nil) -> StoreStatsSnapshot? {
        let defaultSnapshot = defaultStoreID.flatMap { defaultStoreID in
            snapshots.first { $0.siteID == defaultStoreID }
        } ?? snapshots.first

        if let selectedStoreID,
           StoreStatsStoreEntity.isDefaultStoreID(selectedStoreID) {
            return defaultSnapshot
        }

        if let selectedStoreID,
           let selectedStore = snapshots.first(where: { $0.appEntityID == selectedStoreID }) {
            return selectedStore
        }

        return defaultSnapshot
    }
}

/// Data configuration
///
private extension StoreInfoProvider {

    /// Redacted entry with sample data. If dependencies are available — store name and currency
    /// settings will be used. Both the legacy String fields and the metric-driven `metrics`
    /// array derive from `Stats.placeholderSample` + `legacyMetricsPreset` so the two views of
    /// the same data stay in sync.
    ///
    static func placeholderEntry(for dependencies: Dependencies?) -> StoreInfoEntry {
        let currencySettings = dependencies?.storeCurrencySettings ?? CurrencySettings()
        let sample = StoreInfoDataService.Stats.placeholderSample
        let metrics: [StoreInfoMetric] = legacyMetricsPreset.map { type in
            StoreInfoMetric(type: type, value: sample.value(for: type, currencySettings: currencySettings))
        }
        let visitorsString = sample.totalVisitors.map(String.init) ?? StoreInfoFormatter.Constants.valuePlaceholderText
        let conversionString = sample.conversion.map(StoreInfoFormatter.formattedConversionString) ?? StoreInfoFormatter.Constants.valuePlaceholderText
        return .data(.init(
            range: StoreStatsWidgetDateRange.today.localizedRangeLabel,
            name: dependencies?.storeName ?? Localization.myShop,
            revenue: StoreInfoFormatter.formattedAmountString(for: sample.revenue, with: currencySettings),
            revenueCompact: StoreInfoFormatter.formattedAmountCompactString(for: sample.revenue, with: currencySettings),
            visitors: visitorsString,
            orders: "\(sample.totalOrders)",
            conversion: conversionString,
            updatedTime: StoreInfoFormatter.currentFormattedTime(),
            metrics: metrics
        ))
    }

    /// Real data entry. `metrics` is the resolved selection — already family-sliced and topped
    /// up by `resolveMetricSelection` for the AppIntent path, or the legacy hardcoded preset for
    /// the `StaticConfiguration` path. Ordering here is what the home-screen view renders.
    ///
    /// Each `StoreInfoMetric` carries both the current and the previous-period value so the
    /// metric-driven home-screen view can render trend badges. The legacy String fields below
    /// only reflect the current period.
    ///
    static func dataEntry(for statsPeriod: StoreInfoDataService.StatsPeriod,
                          dateRange: StoreStatsWidgetDateRange,
                          with dependencies: Dependencies,
                          metrics: [StoreInfoMetricType]) -> StoreInfoEntry {
        let currencySettings = dependencies.storeCurrencySettings
        let stats = statsPeriod.current
        let previousStats = statsPeriod.previous
        let resolvedMetrics: [StoreInfoMetric] = metrics.map { type in
            StoreInfoMetric(
                type: type,
                value: stats.value(for: type, currencySettings: currencySettings),
                previousValue: previousStats?.value(for: type, currencySettings: currencySettings)
            )
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
            name: dependencies.storeName,
            revenue: StoreInfoFormatter.formattedAmountString(for: stats.revenue, with: currencySettings),
            revenueCompact: StoreInfoFormatter.formattedAmountCompactString(for: stats.revenue, with: currencySettings),
            visitors: visitorsString,
            orders: "\(stats.totalOrders)",
            conversion: conversionString,
            updatedTime: StoreInfoFormatter.currentFormattedTime(),
            metrics: resolvedMetrics
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
