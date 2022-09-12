import WidgetKit
import KeychainAccess

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

    /// Visitors count at the range (eg: today)
    ///
    var visitors: String

    /// Order count at the range (eg: today)
    ///
    var orders: String

    /// Conversion at the range (eg: today)
    ///
    var conversion: String
}

/// Type that provides data entries to the widget system.
///
final class StoreInfoProvider: TimelineProvider {

    /// Holds a reference to the service while a network request is being performed.
    ///
    private var networkService: StoreInfoDataService?

    /// Redacted entry with sample data.
    ///
    func placeholder(in context: Context) -> StoreInfoEntry {
        let dependencies = Self.fetchDependencies()
        return StoreInfoEntry.data(.init(range: Localization.today,
                                         name: dependencies?.storeName ?? Localization.myShop,
                                         revenue: "$132.234",
                                         visitors: "67",
                                         orders: "23",
                                         conversion: "34%"))
    }

    /// Quick Snapshot. Required when previewing the widget.
    ///
    func getSnapshot(in context: Context, completion: @escaping (StoreInfoEntry) -> Void) {
        completion(placeholder(in: context))
    }

    /// Real data widget.
    /// TODO: Update with real data.
    ///
    func getTimeline(in context: Context, completion: @escaping (Timeline<StoreInfoEntry>) -> Void) {
        guard let dependencies = Self.fetchDependencies() else {
            return completion(Timeline<StoreInfoEntry>(entries: [StoreInfoEntry.notConnected], policy: .never))
        }

        let strongService = StoreInfoDataService(authToken: dependencies.authToken)
        networkService = strongService
        Task {
            do {
                let todayStats = try await strongService.fetchTodayStats(for: dependencies.storeID)

                // TODO: Use proper store formatting.
                let entry = StoreInfoEntry.data(.init(range: Localization.today,
                                                      name: dependencies.storeName,
                                                      revenue: "$\(todayStats.revenue)",
                                                      visitors: "\(todayStats.totalVisitors)",
                                                      orders: "\(todayStats.totalOrders)",
                                                      conversion: "\(todayStats.conversion)%"))

                let reloadDate = Date(timeIntervalSinceNow: 30 * 60) // Ask for a 15 minutes reload.
                let timeline = Timeline<StoreInfoEntry>(entries: [entry], policy: .after(reloadDate))
                completion(timeline)

            } catch {
                // TODO: Dispatch network error entry.
                print("Error: \(error)")
            }

        }
    }
}

private extension StoreInfoProvider {

    /// Dependencies needed by the `StoreInfoProvider`
    ///
    struct Dependencies {
        let authToken: String
        let storeID: Int64
        let storeName: String
    }

    /// Fetches the required dependencies from the keychain and the shared users default.
    ///
    static func fetchDependencies() -> Dependencies? {
        let keychain = Keychain(service: WooConstants.keychainServiceName)
        guard let authToken = keychain[WooConstants.authToken],
              let storeID = UserDefaults.group?[.defaultStoreID] as? Int64,
              let storeName = UserDefaults.group?[.defaultStoreName] as? String else {
            return nil
        }
        return Dependencies(authToken: authToken, storeID: storeID, storeName: storeName)
    }
}

private extension StoreInfoProvider {
    enum Localization {
        static let myShop = NSLocalizedString("My Shop", comment: "Generic store name for the store info widget preview")
        static let today = NSLocalizedString("Today", comment: "Range title for the today store info widget")
    }
}
