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
            let timeline = await loadTimeline(dateRange: .today)
            completion(timeline)
        }
    }

    /// Shared loader for both `TimelineProvider` and `AppIntentTimelineProvider` paths.
    /// Visible to extensions in this module so the AppIntent conformance can share logic.
    ///
    func loadTimeline(dateRange: StoreStatsWidgetDateRange) async -> Timeline<StoreInfoEntry> {
        guard let dependencies = Self.fetchDependencies() else {
            return Timeline<StoreInfoEntry>(entries: [.notConnected], policy: .never)
        }

        let reloadDate = Date(timeIntervalSinceNow: reloadInterval)
        let service = StoreInfoDataService(credentials: dependencies.credentials)
        do {
            let stats = try await service.fetchStats(for: dependencies.storeID, dateRange: dateRange.serviceDateRange)
            let entry = Self.dataEntry(for: stats, dateRange: dateRange, with: dependencies)
            return Timeline<StoreInfoEntry>(entries: [entry], policy: .after(reloadDate))
        } catch {
            // WooFoundation does not expose `DDLOG` types. Should we include them?
            print("⛔️ Error fetching today's widget stats: \(error)")
            return Timeline<StoreInfoEntry>(entries: [.error], policy: .after(reloadDate))
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
    }

    /// Fetches the required dependencies from the keychain and the shared users default.
    ///
    static func fetchDependencies() -> Dependencies? {
        let keychain = Keychain(service: WooConstants.keychainServiceName)
        guard let storeID = UserDefaults.group?[.defaultStoreID] as? Int64,
              let storeName = UserDefaults.group?[.defaultStoreName] as? String,
              let storeCurrencySettingsData = UserDefaults.group?[.defaultStoreCurrencySettings] as? Data,
              let storeCurrencySettings = try? JSONDecoder().decode(CurrencySettings.self, from: storeCurrencySettingsData) else {
            print("⛔️ missing store info")
            return nil
        }
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
        return Dependencies(credentials: credentials,
                            storeID: storeID,
                            storeName: storeName,
                            storeCurrencySettings: storeCurrencySettings)
    }
}

/// Data configuration
///
private extension StoreInfoProvider {

    /// Redacted entry with sample data. If dependencies are available - store name and currency settings will be used.
    ///
    static func placeholderEntry(for dependencies: Dependencies?) -> StoreInfoEntry {
        let currencySettings = dependencies?.storeCurrencySettings ?? CurrencySettings()
        let revenueAmount: Decimal = 132.234
        let metrics: [StoreInfoMetric] = [
            StoreInfoMetric(type: .revenue, value: .currency(revenueAmount, currencySettings)),
            StoreInfoMetric(type: .visitors, value: .count(67)),
            StoreInfoMetric(type: .orders, value: .count(23)),
            StoreInfoMetric(type: .conversion, value: .percentage(23.0 / 67.0))
        ]
        return .data(.init(
            range: StoreStatsWidgetDateRange.today.localizedRangeLabel,
            name: dependencies?.storeName ?? Localization.myShop,
            revenue: StoreInfoFormatter.formattedAmountString(for: revenueAmount, with: currencySettings),
            revenueCompact: StoreInfoFormatter.formattedAmountCompactString(for: revenueAmount, with: currencySettings),
            visitors: "67",
            orders: "23",
            conversion: StoreInfoFormatter.formattedConversionString(for: 23.0 / 67.0),
            updatedTime: StoreInfoFormatter.currentFormattedTime(),
            metrics: metrics
        ))
    }

    /// Real data entry.
    ///
    static func dataEntry(for stats: StoreInfoDataService.Stats,
                          dateRange: StoreStatsWidgetDateRange,
                          with dependencies: Dependencies) -> StoreInfoEntry {
        let currencySettings = dependencies.storeCurrencySettings
        let visitorsValue: StoreInfoMetricValue = stats.totalVisitors.map { .count($0) } ?? .unavailable
        let conversionValue: StoreInfoMetricValue = stats.conversion.map { .percentage($0) } ?? .unavailable

        // Medium-widget preset. A later ticket will let users pick this list.
        let metrics: [StoreInfoMetric] = [
            .init(type: .revenue, value: .currency(stats.revenue, currencySettings)),
            .init(type: .visitors, value: visitorsValue),
            .init(type: .orders, value: .count(stats.totalOrders)),
            .init(type: .conversion, value: conversionValue)
        ]

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
            metrics: metrics
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
