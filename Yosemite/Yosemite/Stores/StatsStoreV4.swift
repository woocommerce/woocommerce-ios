import Foundation
import Networking
import Storage

// MARK: - StatsStoreV4
//
public final class StatsStoreV4: Store {
    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: StatsAction.self)
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
        case .retrieveStats(let siteID, let granularity, let latestDateToInclude, let quantity, let onCompletion):
            retrieveStats(siteID: siteID,
                               granularity: granularity,
                               latestDateToInclude: latestDateToInclude,
                               quantity: quantity,
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
    func retrieveStats(siteID: Int, granularity: StatsGranularityV4, latestDateToInclude: Date, quantity: Int, onCompletion: @escaping (Error?) -> Void) {
        let date = String(describing: latestDateToInclude.timeIntervalSinceReferenceDate)
        let remote = OrderStatsRemoteV4(network: network)

        remote.loadOrderStats(for: siteID, unit: granularity, latestDateToInclude: date, quantity: quantity) { [weak self] (orderStatsV4, error) in
            guard let orderStatsV4 = orderStatsV4 else {
                onCompletion(error)
                return
            }

            self?.upsertStoredOrderStats(readOnlyStats: orderStatsV4)
            onCompletion(nil)
        }
    }
}


// MARK: - Persistence
//
extension StatsStoreV4 {
    /// Updates (OR Inserts) the specified ReadOnly OrderStatsV4 Entity into the Storage Layer.
    ///
    func upsertStoredOrderStats(readOnlyStats: Networking.OrderStatsV4) {
        assert(Thread.isMainThread)

        let storage = storageManager.viewStorage
        let storageOrderStats = storage.loadOrderStatsV4(siteID: String(readOnlyStats.siteID), granularity: readOnlyStats.granularity.rawValue) ?? storage.insertNewObject(ofType: Storage.OrderStatsV4.self)
        storageOrderStats.update(with: readOnlyStats)
        handleOrderStatsItems(readOnlyStats, storageOrderStats, storage)
        storage.saveIfNeeded()
    }

    /// Updates the provided StorageOrderStats items using the provided read-only OrderStats items
    ///
    private func handleOrderStatsItems(_ readOnlyStats: Networking.OrderStatsV4, _ storageStats: Storage.OrderStatsV4, _ storage: StorageType) {

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
            if let existingStorageInterval = storage.loadOrderStatsInterval(interval: readOnlyInterval.interval) {
                existingStorageInterval.update(with: readOnlyInterval)
            } else {
                let newStorageInterval = storage.insertNewObject(ofType: Storage.OrderStatsV4Interval.self)
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
