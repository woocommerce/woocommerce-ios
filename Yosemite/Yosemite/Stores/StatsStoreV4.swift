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
                                     let earliestDateToInclude,
                                     let latestDateToInclude,
                                     let onCompletion):
            retrieveTopEarnerStats(siteID: siteID,
                                   timeRange: timeRange,
                                   earliestDateToInclude: earliestDateToInclude,
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
    func retrieveStats(siteID: Int64,
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
    func retrieveSiteVisitStats(siteID: Int64,
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
    func retrieveTopEarnerStats(siteID: Int64,
                                timeRange: StatsTimeRangeV4,
                                earliestDateToInclude: Date,
                                latestDateToInclude: Date,
                                onCompletion: @escaping (Error?) -> Void) {
        let dateFormatter = DateFormatter.Defaults.iso8601WithoutTimeZone
        let earliestDate = dateFormatter.string(from: earliestDateToInclude)
        let latestDate = dateFormatter.string(from: latestDateToInclude)
        let remote = LeaderboardsRemote(network: network)

        remote.loadLeaderboards(for: siteID,
                                unit: timeRange.intervalGranularity,
                                earliestDateToInclude: earliestDate,
                                latestDateToInclude: latestDate,
                                quantity: Constants.defaultTopEarnerStatsLimit) { [weak self] result in
                                    guard let self = self else { return }

                                    switch result {
                                    case .success(let leaderboards):
                                        self.convertAndsStoreLeaderboarsIntoTopEarners(siteID: siteID,
                                                                                       granularity: timeRange.topEarnerStatsGranularity,
                                                                                       date: latestDateToInclude,
                                                                                       leaderboards: leaderboards,
                                                                                       onCompletion: onCompletion)

                                    case .failure(let error):
                                        onCompletion(error)
                                    }
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


// MARK: Convert Leaderboard into TopEarnerStats
//
private extension StatsStoreV4 {

    /// Converts and stores a top-product `leaderboard` into a `StatsTopEarner`
    /// Since  a `leaderboard` does not containt  the necesary product information, this method fetches the related product before starting the convertion.
    ///
    private func convertAndsStoreLeaderboarsIntoTopEarners(siteID: Int64,
                                                           granularity: StatGranularity,
                                                           date: Date,
                                                           leaderboards: [Leaderboard],
                                                           onCompletion: @escaping (Error?) -> Void) {

        // API guarantees a fixed index for the top products leaderboard
        let topProducts = leaderboards[Constants.topProductsIndex]

        // Make sure we have all the necesary product data before converting and storing top earners.
        loadProducts(for: topProducts, siteID: siteID) { [weak self] topProductsResult in
            guard let self = self else { return }

            switch topProductsResult {
            case .success(let products):
                self.mergeAndStoreTopProductsAndStoredProductsIntoTopEarners(granularity: granularity,
                                                                             date: date,
                                                                             topProducts: topProducts,
                                                                             storedProducts: products)
                onCompletion(nil)

            case .failure(let error):
                onCompletion(error)
            }
        }
    }

    /// Loads product objects that relates to the top products on a `leaderboard`
    /// If product objects can't be found in the storage layer, they will be fetched from the remote layer.
    ///
    private func loadProducts(for topProducts: Leaderboard, siteID: Int64, completion: @escaping (Result<[Product], Error>) -> Void) {

        // Workout if we have stored all products that relate to the given leaderboard
        let topProductIDs = LeaderboardStatsConverter.topProductsIDs(from: topProducts)
        let topStoredProducts = loadStoredProducts(siteID: siteID, productIDs: topProductIDs)
        let missingProductsIDs = LeaderboardStatsConverter.missingProductsIDs(from: topProducts, in: topStoredProducts)

        // Return if we have al the products that we need
        guard !missingProductsIDs.isEmpty else {
            completion(.success(topStoredProducts))
            return
        }

        // Fetch the products that we have not downloaded and stored yet
        let productsRemote = ProductsRemote(network: network)
        productsRemote.loadProducts(for: siteID, by: missingProductsIDs) { result in
            switch result {
            case .success(let products):
                // Return the complete array of products that corresponds to a top product leaderboard
                let completeTopProducts = products + topStoredProducts
                completion(.success(completeTopProducts))

            case .failure:
                completion(result)
            }
        }
    }

    /// Returns all stored products for a given site ID
    ///
    private func loadStoredProducts(siteID: Int64, productIDs: [Int64] ) -> [Networking.Product] {
        let products = storageManager.viewStorage.loadProducts(siteID: siteID, productsIDs: productIDs)
        return products.map { $0.toReadOnly() }
    }

    /// Merges and stored a top-product leaderboard with an array of stored products into  a `StatsTopEarner` object
    ///
    private func mergeAndStoreTopProductsAndStoredProductsIntoTopEarners(granularity: StatGranularity,
                                                                         date: Date,
                                                                         topProducts: Leaderboard,
                                                                         storedProducts: [Product]) {
        let statsDate = StatsStore.buildDateString(from: date, with: granularity)
        let statsItems = LeaderboardStatsConverter.topEearnerStatItems(from: topProducts, using: storedProducts)
        let stats = TopEarnerStats(date: statsDate,
                                   granularity: granularity,
                                   limit: String(Constants.defaultTopEarnerStatsLimit),
                                   items: statsItems
        )

        upsertStoredTopEarnerStats(readOnlyStats: stats)
    }
}

// MARK: - Constants!
//
private extension StatsStoreV4 {

    enum Constants {

        /// Default limit value for TopEarnerStats
        ///
        static let defaultTopEarnerStatsLimit: Int = 3

        /// Index of top products in leaderboards API
        ///
        static let topProductsIndex = 3
    }
}
