import Foundation
import Networking
import Storage


// MARK: - StatsStoreV4
//
public final class StatsStoreV4: Store {
    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: StatsActionV4.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? StatsActionV4 else {
            assertionFailure("OrderStatsStoreV4 received an unsupported action")
            return
        }

        switch action {
        case .resetStoredStats(let onCompletion):
            resetStoredStats(onCompletion: onCompletion)
        case .retrieveStats(let siteID,
                            let timeRange,
                            let earliestDateToInclude,
                            let latestDateToInclude,
                            let quantity,
                            let onCompletion):
            retrieveStats(siteID: siteID,
                          timeRange: timeRange,
                          earliestDateToInclude: earliestDateToInclude,
                          latestDateToInclude: latestDateToInclude,
                          quantity: quantity,
                          onCompletion: onCompletion)
        case .retrieveSiteVisitStats(let siteID,
                                     let siteTimezone,
                                     let timeRange,
                                     let latestDateToInclude,
                                     let onCompletion):
            retrieveSiteVisitStats(siteID: siteID,
                                   siteTimezone: siteTimezone,
                                   timeRange: timeRange,
                                   latestDateToInclude: latestDateToInclude,
                                   onCompletion: onCompletion)
        case .retrieveTopEarnerStats(let siteID,
                                     let timeRange,
                                     let latestDateToInclude,
                                     let onCompletion):
            retrieveTopEarnerStats(siteID: siteID,
                                   timeRange: timeRange,
                                   latestDateToInclude: latestDateToInclude,
                                   onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
public extension StatsStoreV4 {
    /// Deletes all of the Stats data.
    ///
    func resetStoredStats(onCompletion: () -> Void) {
        let storage = storageManager.viewStorage
        storage.deleteAllObjects(ofType: Storage.OrderStatsV4.self)
        storage.deleteAllObjects(ofType: Storage.OrderStatsV4Totals.self)
        storage.deleteAllObjects(ofType: Storage.OrderStatsV4Interval.self)
        storage.saveIfNeeded()
        DDLogDebug("Stats V4 deleted")

        onCompletion()
    }

    /// Retrieves the order stats associated with the provided Site ID (if any!).
    ///
    func retrieveStats(siteID: Int,
                       timeRange: StatsTimeRangeV4,
                       earliestDateToInclude: Date,
                       latestDateToInclude: Date,
                       quantity: Int,
                       onCompletion: @escaping (Error?) -> Void) {
        let dateFormatter = DateFormatter.Defaults.iso8601WithoutTimeZone
        let earliestDate = dateFormatter.string(from: earliestDateToInclude)
        let latestDate = dateFormatter.string(from: latestDateToInclude)
        let remote = OrderStatsRemoteV4(network: network)

        remote.loadOrderStats(for: siteID,
                              unit: timeRange.intervalGranularity,
                              earliestDateToInclude: earliestDate,
                              latestDateToInclude: latestDate,
                              quantity: quantity) { [weak self] (orderStatsV4, error) in
            guard let orderStatsV4 = orderStatsV4 else {
                onCompletion(error)
                return
            }

            self?.upsertStoredOrderStats(readOnlyStats: orderStatsV4, timeRange: timeRange)
            onCompletion(nil)
        }
    }

    /// Retrieves the site visit stats associated with the provided Site ID (if any!).
    ///
    func retrieveSiteVisitStats(siteID: Int,
                                siteTimezone: TimeZone,
                                timeRange: StatsTimeRangeV4,
                                latestDateToInclude: Date,
                                onCompletion: @escaping (Error?) -> Void) {

        let quantity = timeRange.siteVisitStatsQuantity(date: latestDateToInclude, siteTimezone: siteTimezone)

        let remote = SiteVisitStatsRemote(network: network)
        remote.loadSiteVisitorStats(for: siteID,
                                    siteTimezone: siteTimezone,
                                    unit: timeRange.siteVisitStatsGranularity,
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
    func retrieveTopEarnerStats(siteID: Int,
                                timeRange: StatsTimeRangeV4,
                                latestDateToInclude: Date,
                                onCompletion: @escaping (Error?) -> Void) {
        let remote = TopEarnersStatsRemote(network: network)
        let granularity = timeRange.topEarnerStatsGranularity
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
}


// MARK: - Persistence
//
extension StatsStoreV4 {
    /// Updates (OR Inserts) the specified ReadOnly OrderStatsV4 Entity into the Storage Layer.
    ///
    func upsertStoredOrderStats(readOnlyStats: Networking.OrderStatsV4, timeRange: StatsTimeRangeV4) {
        assert(Thread.isMainThread)

        let storage = storageManager.viewStorage

        let storageOrderStats = storage.loadOrderStatsV4(siteID: readOnlyStats.siteID, timeRange: timeRange.rawValue) ??
            storage.insertNewObject(ofType: Storage.OrderStatsV4.self)

        storageOrderStats.timeRange = timeRange.rawValue
        storageOrderStats.totals = storage.insertNewObject(ofType: Storage.OrderStatsV4Totals.self)
        storageOrderStats.update(with: readOnlyStats)
        handleOrderStatsIntervals(readOnlyStats, storageOrderStats, storage)
        storage.saveIfNeeded()
    }

    /// Updates the provided StorageOrderStats items using the provided read-only OrderStats items
    ///
    private func handleOrderStatsIntervals(_ readOnlyStats: Networking.OrderStatsV4, _ storageStats: Storage.OrderStatsV4, _ storage: StorageType) {
        let readOnlyIntervals = readOnlyStats.intervals

        if readOnlyIntervals.isEmpty {
            // No items in the read-only order stats, so remove all the intervals in Storage.OrderStatsV4
            storageStats.intervals?.forEach {
                storageStats.removeFromIntervals($0)
                storage.deleteObject($0)
            }
            return
        }

        // Upsert the items from the read-only order stats item
        for readOnlyInterval in readOnlyIntervals {
            if let existingStorageInterval = storage.loadOrderStatsInterval(interval: readOnlyInterval.interval,
                                                                            orderStats: storageStats) {
                existingStorageInterval.update(with: readOnlyInterval)
                existingStorageInterval.stats = storageStats
            } else {
                let newStorageInterval = storage.insertNewObject(ofType: Storage.OrderStatsV4Interval.self)
                newStorageInterval.subtotals = storage.insertNewObject(ofType: Storage.OrderStatsV4Totals.self)
                newStorageInterval.update(with: readOnlyInterval)
                storageStats.addToIntervals(newStorageInterval)
            }
        }

        // Now, remove any objects that exist in storageStats.intervals but not in readOnlyStats.intervals
        storageStats.intervals?.forEach({ storageInterval in
            if readOnlyIntervals.first(where: { $0.interval == storageInterval.interval } ) == nil {
                storageStats.removeFromIntervals(storageInterval)
                storage.deleteObject(storageInterval)
            }
        })
    }
}

// MARK: Site visit stats
//
extension StatsStoreV4 {
    /// Updates (OR Inserts) the specified ReadOnly SiteVisitStats Entity into the Storage Layer.
    ///
    func upsertStoredSiteVisitStats(readOnlyStats: Networking.SiteVisitStats) {
        assert(Thread.isMainThread)

        let storage = storageManager.viewStorage
        let storageSiteVisitStats = storage.loadSiteVisitStats(
            granularity: readOnlyStats.granularity.rawValue, date: readOnlyStats.date) ?? storage.insertNewObject(ofType: Storage.SiteVisitStats.self)
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
}

extension StatsStoreV4 {
    /// Updates (OR Inserts) the specified ReadOnly TopEarnerStats Entity into the Storage Layer.
    ///
    func upsertStoredTopEarnerStats(readOnlyStats: Networking.TopEarnerStats) {
        assert(Thread.isMainThread)

        let storage = storageManager.viewStorage
        let storageTopEarnerStats = storage.loadTopEarnerStats(date: readOnlyStats.date,
                                                               granularity: readOnlyStats.granularity.rawValue)
            ?? storage.insertNewObject(ofType: Storage.TopEarnerStats.self)
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
}

// MARK: - Constants!
//
private extension StatsStoreV4 {

    enum Constants {

        /// Default limit value for TopEarnerStats
        ///
        static let defaultTopEarnerStatsLimit: Int = 3
    }
}
