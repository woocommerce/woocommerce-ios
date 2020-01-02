import Foundation
import Networking
import Storage


// MARK: - StatsStore
//
public class StatsStore: Store {

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: StatsAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? StatsAction else {
            assertionFailure("OrderStatsStore received an unsupported action")
            return
        }

        switch action {
        case .resetStoredStats(let onCompletion):
            resetStoredStats(onCompletion: onCompletion)
        case .retrieveOrderStats(let siteID, let granularity, let latestDateToInclude, let quantity, let onCompletion):
            retrieveOrderStats(siteID: siteID,
                               granularity: granularity,
                               latestDateToInclude: latestDateToInclude,
                               quantity: quantity,
                               onCompletion: onCompletion)
        case .retrieveSiteVisitStats(let siteID, let granularity, let latestDateToInclude, let quantity, let onCompletion):
            retrieveSiteVisitStats(siteID: siteID,
                                   granularity: granularity,
                                   latestDateToInclude: latestDateToInclude,
                                   quantity: quantity,
                                   onCompletion: onCompletion)
        case .retrieveTopEarnerStats(let siteID, let granularity, let latestDateToInclude, let onCompletion):
            retrieveTopEarnerStats(siteID: siteID, granularity: granularity, latestDateToInclude: latestDateToInclude, onCompletion: onCompletion)
        case .retrieveOrderTotals(let siteID, let status, let onCompletion):
            retrieveOrderTotals(siteID: siteID, statusEnum: status, onCompletion: onCompletion)
        }
    }
}


// MARK: - Public Helpers
//
public extension StatsStore {

    /// Converts a Date into the appropriately formatted string based on the `OrderStatGranularity`
    ///
    static func buildDateString(from date: Date, with granularity: StatGranularity) -> String {
        switch granularity {
        case .day:
            return DateFormatter.Stats.statsDayFormatter.string(from: date)
        case .week:
            return DateFormatter.Stats.statsWeekFormatter.string(from: date)
        case .month:
            return DateFormatter.Stats.statsMonthFormatter.string(from: date)
        case .year:
            return DateFormatter.Stats.statsYearFormatter.string(from: date)
        }
    }
}


// MARK: - Services!
//
private extension StatsStore {

    /// Deletes all of the Stats data.
    ///
    func resetStoredStats(onCompletion: () -> Void) {
        let storage = storageManager.viewStorage
        storage.deleteAllObjects(ofType: Storage.OrderStats.self)
        storage.deleteAllObjects(ofType: Storage.SiteVisitStats.self)
        storage.deleteAllObjects(ofType: Storage.TopEarnerStats.self)
        storage.saveIfNeeded()
        DDLogDebug("Stats deleted")

        onCompletion()
    }

    /// Retrieves the order stats associated with the provided Site ID (if any!).
    ///
    func retrieveOrderStats(siteID: Int64, granularity: StatGranularity, latestDateToInclude: Date, quantity: Int, onCompletion: @escaping (Error?) -> Void) {

        let remote = OrderStatsRemote(network: network)
        let formattedDateString = StatsStore.buildDateString(from: latestDateToInclude, with: granularity)

        remote.loadOrderStats(for: siteID, unit: granularity, latestDateToInclude: formattedDateString, quantity: quantity) { [weak self] (orderStats, error) in
            guard let orderStats = orderStats else {
                onCompletion(error)
                return
            }

            self?.upsertStoredOrderStats(readOnlyStats: orderStats)
            onCompletion(nil)
        }
    }

    /// Retrieves the site visit stats associated with the provided Site ID (if any!).
    ///
    func retrieveSiteVisitStats(siteID: Int64,
                                granularity: StatGranularity,
                                latestDateToInclude: Date,
                                quantity: Int,
                                onCompletion: @escaping (Error?) -> Void) {

        let remote = SiteVisitStatsRemote(network: network)

        remote.loadSiteVisitorStats(for: siteID,
                                    unit: granularity,
                                    latestDateToInclude: latestDateToInclude,
                                    quantity: quantity) { [weak self] (siteVisitStats, error) in
            guard let siteVisitStats = siteVisitStats else {
                onCompletion(error.map({ SiteVisitStatsStoreError(error: $0) }))
                return
            }

            self?.upsertStoredSiteVisitStats(readOnlyStats: siteVisitStats)
            onCompletion(nil)
        }
    }

    /// Retrieves the top earner stats associated with the provided Site ID (if any!).
    ///
    func retrieveTopEarnerStats(siteID: Int64, granularity: StatGranularity, latestDateToInclude: Date, onCompletion: @escaping (Error?) -> Void) {

        let remote = TopEarnersStatsRemote(network: network)
        let formattedDateString = StatsStore.buildDateString(from: latestDateToInclude, with: granularity)

        remote.loadTopEarnersStats(for: siteID,
                                   unit: granularity,
                                   latestDateToInclude: formattedDateString,
                                   limit: Constants.defaultTopEarnerStatsLimit) { [weak self] (topEarnerStats, error) in
            guard let topEarnerStats = topEarnerStats else {
                onCompletion(error)
                return
            }

            self?.upsertStoredTopEarnerStats(readOnlyStats: topEarnerStats)
            onCompletion(nil)
        }
    }

    /// Retrieves current order totals for the given site & status
    ///
    func retrieveOrderTotals(siteID: Int64, statusEnum: OrderStatusEnum, onCompletion: @escaping (Int?, Error?) -> Void) {
        let remote = ReportRemote(network: network)
        remote.loadOrderTotals(for: siteID) { (orderTotals, error) in
            onCompletion(orderTotals?[statusEnum], error)
        }
    }
}


// MARK: - Persistence
//
extension StatsStore {

    /// Updates (OR Inserts) the specified ReadOnly TopEarnerStats Entity into the Storage Layer.
    ///
    func upsertStoredTopEarnerStats(readOnlyStats: Networking.TopEarnerStats) {
        assert(Thread.isMainThread)

        let storage = storageManager.viewStorage
        let storageTopEarnerStats = storage.loadTopEarnerStats(date: readOnlyStats.date,
                                               granularity: readOnlyStats.granularity.rawValue) ?? storage.insertNewObject(ofType: Storage.TopEarnerStats.self)
        storageTopEarnerStats.update(with: readOnlyStats)
        handleTopEarnerStatsItems(readOnlyStats, storageTopEarnerStats, storage)
        storage.saveIfNeeded()
    }

    /// Updates the provided StorageTopEarnerStats items using the provided read-only TopEarnerStats items
    ///
    private func handleTopEarnerStatsItems(_ readOnlyStats: Networking.TopEarnerStats,
                                           _ storageTopEarnerStats: Storage.TopEarnerStats,
                                           _ storage: StorageType) {

        // Since we are treating the items in core data like a dumb cache, start by nuking all of the existing stored TopEarnerStatsItems
        storageTopEarnerStats.items?.forEach {
            storageTopEarnerStats.removeFromItems($0)
            storage.deleteObject($0)
        }

        // Insert the items from the read-only stats
        readOnlyStats.items?.forEach({ readOnlyItem in
            let newStorageItem = storage.insertNewObject(ofType: Storage.TopEarnerStatsItem.self)
            newStorageItem.update(with: readOnlyItem)
            storageTopEarnerStats.addToItems(newStorageItem)
        })
    }

    /// Updates (OR Inserts) the specified ReadOnly SiteVisitStats Entity into the Storage Layer.
    ///
    func upsertStoredSiteVisitStats(readOnlyStats: Networking.SiteVisitStats) {
        assert(Thread.isMainThread)

        let storage = storageManager.viewStorage
        let storageSiteVisitStats = storage.loadSiteVisitStats(
            granularity: readOnlyStats.granularity.rawValue) ?? storage.insertNewObject(ofType: Storage.SiteVisitStats.self)
        storageSiteVisitStats.update(with: readOnlyStats)
        handleSiteVisitStatsItems(readOnlyStats, storageSiteVisitStats, storage)
        storage.saveIfNeeded()
    }

    /// Updates the provided StorageSiteVisitStats items using the provided read-only SiteVisitStats items
    ///
    private func handleSiteVisitStatsItems(_ readOnlyStats: Networking.SiteVisitStats,
                                           _ storageSiteVisitStats: Storage.SiteVisitStats,
                                           _ storage: StorageType) {

        // Since we are treating the items in core data like a dumb cache, start by nuking all of the existing stored SiteVisitStatsItems
        storageSiteVisitStats.items?.forEach {
            storageSiteVisitStats.removeFromItems($0)
            storage.deleteObject($0)
        }

        // Insert the items from the read-only stats
        readOnlyStats.items?.forEach({ readOnlyItem in
            let newStorageItem = storage.insertNewObject(ofType: Storage.SiteVisitStatsItem.self)
            newStorageItem.update(with: readOnlyItem)
            storageSiteVisitStats.addToItems(newStorageItem)
        })
    }

    /// Updates (OR Inserts) the specified ReadOnly OrderStats Entity into the Storage Layer.
    ///
    func upsertStoredOrderStats(readOnlyStats: Networking.OrderStats) {
        assert(Thread.isMainThread)

        let storage = storageManager.viewStorage
        let storageOrderStats = storage.loadOrderStats(
            granularity: readOnlyStats.granularity.rawValue) ?? storage.insertNewObject(ofType: Storage.OrderStats.self)
        storageOrderStats.update(with: readOnlyStats)
        handleOrderStatsItems(readOnlyStats, storageOrderStats, storage)
        storage.saveIfNeeded()
    }

    /// Updates the provided StorageOrderStats items using the provided read-only OrderStats items
    ///
    private func handleOrderStatsItems(_ readOnlyStats: Networking.OrderStats, _ storageStats: Storage.OrderStats, _ storage: StorageType) {

        guard let readOnlyItems = readOnlyStats.items, !readOnlyItems.isEmpty else {
            // No items in the read-only order stats, so remove all the items in Storage.OrderStats
            storageStats.items?.forEach {
                storageStats.removeFromItems($0)
                storage.deleteObject($0)
            }
            return
        }

        // Upsert the items from the read-only order stats item
        for readOnlyItem in readOnlyItems {
            if let existingStorageItem = storage.loadOrderStatsItem(period: readOnlyItem.period) {
                existingStorageItem.update(with: readOnlyItem)
            } else {
                let newStorageItem = storage.insertNewObject(ofType: Storage.OrderStatsItem.self)
                newStorageItem.update(with: readOnlyItem)
                storageStats.addToItems(newStorageItem)
            }
        }

        // Now, remove any objects that exist in storageStats.items but not in readOnlyStats.items
        storageStats.items?.forEach({ storageItem in
            if readOnlyItems.first(where: { $0.period == storageItem.period } ) == nil {
                storageStats.removeFromItems(storageItem)
                storage.deleteObject(storageItem)
            }
        })
    }
}


// MARK: - Constants!
//
extension StatsStore {

    enum Constants {

        /// Default limit value for TopEarnerStats
        ///
        static let defaultTopEarnerStatsLimit: Int = 3
    }
}

/// An error that occurs while fetching site visit stats.
///
/// - noPermission: the user has no permission to view site stats.
/// - statsModuleDisabled: Jetpack site stats module is disabled for the site.
/// - unknown: other error cases.
///
public enum SiteVisitStatsStoreError: Error {
    case statsModuleDisabled
    case noPermission
    case unknown

    init(error: Error) {
        guard let dotcomError = error as? DotcomError else {
            self = .unknown
            return
        }
        switch dotcomError {
        case .noStatsPermission:
            self = .noPermission
        case .statsModuleDisabled:
            self = .statsModuleDisabled
        default:
            self = .unknown
        }
    }
}
