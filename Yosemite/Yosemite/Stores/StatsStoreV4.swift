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
            //
        }

//        let remote = OrderStatsRemote(network: network)
//        let formattedDateString = StatsStore.buildDateString(from: latestDateToInclude, with: granularity)
//
//        remote.loadOrderStats(for: siteID, unit: granularity, latestDateToInclude: formattedDateString, quantity: quantity) { [weak self] (orderStats, error) in
//            guard let orderStats = orderStats else {
//                onCompletion(error)
//                return
//            }
//
//            self?.upsertStoredOrderStats(readOnlyStats: orderStats)
//            onCompletion(nil)
//        }
    }
}
