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
        case .retrieveOrderStats(let siteID, let granularity, let latestDateToInclude, let quantity, let onCompletion):
            retrieveOrderStats(siteID: siteID, granularity: granularity, latestDateToInclude: latestDateToInclude,  quantity: quantity, onCompletion: onCompletion)
        case .retrieveSiteVisitStats(let siteID, let granularity, let latestDateToInclude, let quantity, let onCompletion):
            retrieveSiteVisitStats(siteID: siteID, granularity: granularity, latestDateToInclude: latestDateToInclude,  quantity: quantity, onCompletion: onCompletion)
        case .retrieveTopEarnerStats(let siteID, let granularity, let latestDateToInclude, let onCompletion):
            retrieveTopEarnerStats(siteID: siteID, granularity: granularity, latestDateToInclude: latestDateToInclude, onCompletion: onCompletion)
        }
    }
}


// MARK: - Public Helpers
//
public extension StatsStore  {

    /// Converts a Date into the appropriatly formatted string based on the `OrderStatGranularity`
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
private extension StatsStore  {

    /// Retrieves the order stats associated with the provided Site ID (if any!).
    ///
    func retrieveOrderStats(siteID: Int, granularity: StatGranularity, latestDateToInclude: Date, quantity: Int, onCompletion: @escaping (OrderStats?, Error?) -> Void) {

        let remote = OrderStatsRemote(network: network)
        let formattedDateString = StatsStore.buildDateString(from: latestDateToInclude, with: granularity)

        remote.loadOrderStats(for: siteID, unit: granularity, latestDateToInclude: formattedDateString, quantity: quantity) { (orderStats, error) in
            guard let orderStats = orderStats else {
                onCompletion(nil, error)
                return
            }

            onCompletion(orderStats, nil)
        }
    }

    /// Retrieves the site visit stats associated with the provided Site ID (if any!).
    ///
    func retrieveSiteVisitStats(siteID: Int, granularity: StatGranularity, latestDateToInclude: Date, quantity: Int, onCompletion: @escaping (Error?) -> Void) {

        let remote = SiteVisitStatsRemote(network: network)

        remote.loadSiteVisitorStats(for: siteID, unit: granularity, latestDateToInclude: latestDateToInclude, quantity: quantity) { [weak self] (siteVisitStats, error) in
            guard let siteVisitStats = siteVisitStats else {
                onCompletion(error)
                return
            }


            self?.upsertStoredSiteVisitStats(readOnlyStats: siteVisitStats)
            onCompletion(nil)
        }
    }

    /// Retrieves the top earner stats associated with the provided Site ID (if any!).
    ///
    func retrieveTopEarnerStats(siteID: Int, granularity: StatGranularity, latestDateToInclude: Date, onCompletion: @escaping (Error?) -> Void) {

        let remote = TopEarnersStatsRemote(network: network)
        let formattedDateString = StatsStore.buildDateString(from: latestDateToInclude, with: granularity)

        remote.loadTopEarnersStats(for: siteID, unit: granularity, latestDateToInclude: formattedDateString, limit: Constants.defaultTopEarnerStatsLimit) { [weak self] (topEarnerStats, error) in
            guard let topEarnerStats = topEarnerStats else {
                onCompletion(error)
                return
            }

            self?.upsertStoredTopEarnerStats(readOnlyStats: topEarnerStats)
            onCompletion(nil)
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

    /// Updates the provided StorageTopEarnerStats' items using the provided read-only TopEarnerStats' items
    ///
    private func handleTopEarnerStatsItems(_ readOnlyStats: Networking.TopEarnerStats, _ storageTopEarnerStats: Storage.TopEarnerStats, _ storage: StorageType) {

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
        let storageSiteVisitStats = storage.loadSiteVisitStats(granularity: readOnlyStats.granularity.rawValue) ?? storage.insertNewObject(ofType: Storage.SiteVisitStats.self)
        storageSiteVisitStats.update(with: readOnlyStats)
        handleSiteVisitStatsItems(readOnlyStats, storageSiteVisitStats, storage)
        storage.saveIfNeeded()
    }

    /// Updates the provided StorageSiteVisitStats' items using the provided read-only TopEarnerStats' items
    ///
    private func handleSiteVisitStatsItems(_ readOnlyStats: Networking.SiteVisitStats, _ storageTopEarnerStats: Storage.SiteVisitStats, _ storage: StorageType) {

        // Since we are treating the items in core data like a dumb cache, start by nuking all of the existing stored SiteVisitStatsItems
        storageTopEarnerStats.items?.forEach {
            storageTopEarnerStats.removeFromItems($0)
            storage.deleteObject($0)
        }

        // Insert the items from the read-only stats
        readOnlyStats.items?.forEach({ readOnlyItem in
            let newStorageItem = storage.insertNewObject(ofType: Storage.SiteVisitStatsItem.self)
            newStorageItem.update(with: readOnlyItem)
            storageTopEarnerStats.addToItems(newStorageItem)
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
