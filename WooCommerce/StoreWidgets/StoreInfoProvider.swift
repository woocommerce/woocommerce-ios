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
}

/// Type that provides data entries to the widget system.
///
final class StoreInfoProvider: TimelineProvider {

    /// Holds a reference to the service while a network request is being performed.
    ///
    private var networkService: StoreInfoDataService?

    /// Desired data reload interval provided to system = 30 minutes.
    ///
    private let reloadInterval: TimeInterval = 30 * 60

    /// Redacted entry with sample data.
    ///
    func placeholder(in context: Context) -> StoreInfoEntry {
        let dependencies = Self.fetchDependencies()
        return Self.placeholderEntry(for: dependencies)
    }

    /// Quick Snapshot. Required when previewing the widget.
    ///
    func getSnapshot(in context: Context, completion: @escaping (StoreInfoEntry) -> Void) {
        completion(placeholder(in: context))
    }

    /// Real data widget.
    ///
    func getTimeline(in context: Context, completion: @escaping (Timeline<StoreInfoEntry>) -> Void) {
        guard let dependencies = Self.fetchDependencies() else {
            return completion(Timeline<StoreInfoEntry>(entries: [StoreInfoEntry.notConnected], policy: .never))
        }

        let strongService = StoreInfoDataService(credentials: dependencies.credentials)
        networkService = strongService
        Task {
            do {
                let todayStats = try await strongService.fetchTodayStats(for: dependencies.storeID)
                let entry = Self.dataEntry(for: todayStats, with: dependencies)
                let reloadDate = Date(timeIntervalSinceNow: reloadInterval)
                let timeline = Timeline<StoreInfoEntry>(entries: [entry], policy: .after(reloadDate))
                completion(timeline)
            } catch {
                // WooFoundation does not expose `DDLOG` types. Should we include them?
                print("⛔️ Error fetching today's widget stats: \(error)")

                let reloadDate = Date(timeIntervalSinceNow: reloadInterval)
                let timeline = Timeline<StoreInfoEntry>(entries: [.error], policy: .after(reloadDate))
                completion(timeline)
            }
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
        StoreInfoEntry.data(.init(range: Localization.today,
                                  name: dependencies?.storeName ?? Localization.myShop,
                                  revenue: StoreInfoFormatter.formattedAmountString(for: 132.234, with: dependencies?.storeCurrencySettings),
                                  revenueCompact: StoreInfoFormatter.formattedAmountCompactString(for: 132.234, with: dependencies?.storeCurrencySettings),
                                  visitors: "67",
                                  orders: "23",
                                  conversion: StoreInfoFormatter.formattedConversionString(for: 23/67),
                                  updatedTime: StoreInfoFormatter.currentFormattedTime()))
    }

    /// Real data entry.
    ///
    static func dataEntry(for todayStats: StoreInfoDataService.Stats, with dependencies: Dependencies) -> StoreInfoEntry {
        let visitors: String = {
            if let visitors = todayStats.totalVisitors {
                return "\(visitors)"
            }
            return StoreInfoFormatter.Constants.valuePlaceholderText
        }()
        let conversion: String = {
            if let conversion = todayStats.conversion {
                return StoreInfoFormatter.formattedConversionString(for: conversion)
            }
            return StoreInfoFormatter.Constants.valuePlaceholderText
        }()
        return StoreInfoEntry.data(.init(range: Localization.today,
                                         name: dependencies.storeName,
                                         revenue: StoreInfoFormatter.formattedAmountString(for: todayStats.revenue, with: dependencies.storeCurrencySettings),
                                         revenueCompact: StoreInfoFormatter.formattedAmountCompactString(for: todayStats.revenue,
                                                                                                         with: dependencies.storeCurrencySettings),
                                         visitors: visitors,
                                         orders: "\(todayStats.totalOrders)",
                                         conversion: conversion,
                                         updatedTime: StoreInfoFormatter.currentFormattedTime()))
    }

    enum Localization {
        static let myShop = AppLocalizedString(
            "storeWidgets.infoProvider.myShop",
            value: "My Shop",
            comment: "Generic store name for the store info widget preview"
        )
        static let today = AppLocalizedString(
            "storeWidgets.infoProvider.today",
            value: "Today",
            comment: "Range title for the today store info widget"
        )
    }
}
