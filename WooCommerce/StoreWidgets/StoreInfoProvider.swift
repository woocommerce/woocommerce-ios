import WidgetKit
import WooFoundation
import KeychainAccess
import Networking

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
            metrics: StoreStatsConfigurationIntent.resolveMetricSelection(
                requested: StoreStatsConfigurationIntent.defaultMetrics,
                family: context.family
            )
        )
    }

    func placeholder(for configuration: StoreStatsConfigurationIntent, in context: Context) -> StoreInfoEntry {
        Self.placeholderEntry(
            for: Self.fetchDependencies(),
            dateRange: configuration.dateRange,
            metrics: StoreStatsConfigurationIntent.resolveMetricSelection(
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
            let statsPeriod = try await service.fetchStats(
                for: dependencies.store.storeID,
                dateRange: dateRange.serviceDateRange(timezone: dependencies.store.storeTimeZone)
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

// MARK: - Metric presets

extension StoreInfoProvider {
    /// Hardcoded preset used by the legacy `StaticConfiguration` path (`getTimeline`) and as the
    /// fallback placeholder selection. Matches the original 4-cell shape — non-WPCom users see
    /// `visitors` / `conversion` as `.unavailable`. Real AppIntent timelines and snapshots
    /// derive their selection from the user's stored configuration.
    ///
    static let legacyMetricsPreset: [StoreInfoMetricType] = [
        .revenue, .visitors, .orders, .conversion
    ]

    static func placeholderEntry(
        dateRange: StoreStatsWidgetDateRange = .today,
        metrics: [StoreInfoMetricType] = legacyMetricsPreset
    ) -> StoreInfoEntry {
        placeholderEntry(for: fetchDependencies(), dateRange: dateRange, metrics: metrics)
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

private extension StoreInfoProvider {

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
                                      sites: [WidgetSite]) -> StoreMetadata {
        guard let selectedStoreID,
              StoreStatsStoreSelection.isDefaultStoreEntityID(selectedStoreID) == false,
              let selectedSiteID = Int64(selectedStoreID),
              let selectedSite = sites.first(where: { $0.siteID == selectedSiteID }) else {
            return defaultStore
        }

        let currencySettings: CurrencySettings = {
            guard selectedSite.siteID != defaultStore.storeID else {
                return defaultStore.storeCurrencySettings
            }
            return selectedSite.currencySettings ?? defaultStore.storeCurrencySettings
        }()

        return StoreMetadata(storeID: selectedSite.siteID,
                             storeName: selectedSite.name,
                             storeCurrencySettings: currencySettings,
                             storeTimeZone: selectedSite.timezone)
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
                             storeTimeZone: sites.first(where: { $0.siteID == storeID })?.timezone ?? .current)
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
            metricSlots: metricSlots,
            dateRange: dateRange
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
