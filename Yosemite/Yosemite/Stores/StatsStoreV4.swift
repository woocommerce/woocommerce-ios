import Foundation
import Networking
import Storage
import WooFoundation

// MARK: - StatsStoreV4
//
public final class StatsStoreV4: Store {
    private let siteStatsRemote: SiteStatsRemote
    private let leaderboardsRemote: LeaderboardsRemote
    private let orderStatsRemote: OrderStatsRemoteV4
    private let productsRemote: ProductsRemote

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.siteStatsRemote = SiteStatsRemote(network: network)
        self.leaderboardsRemote = LeaderboardsRemote(network: network)
        self.orderStatsRemote = OrderStatsRemoteV4(network: network)
        self.productsRemote = ProductsRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

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
                            let forceRefresh,
                            let onCompletion):
            retrieveStats(siteID: siteID,
                          timeRange: timeRange,
                          earliestDateToInclude: earliestDateToInclude,
                          latestDateToInclude: latestDateToInclude,
                          quantity: quantity,
                          forceRefresh: forceRefresh,
                          onCompletion: onCompletion)
        case .retrieveCustomStats(let siteID,
                                  let unit,
                                  let earliestDateToInclude,
                                  let latestDateToInclude,
                                  let quantity,
                                  let forceRefresh,
                                  let onCompletion):
            retrieveCustomStats(siteID: siteID,
                                unit: unit,
                                earliestDateToInclude: earliestDateToInclude,
                                latestDateToInclude: latestDateToInclude,
                                quantity: quantity,
                                forceRefresh: forceRefresh,
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
                                     let quantity,
                                     let forceRefresh,
                                     let saveInStorage,
                                     let onCompletion):
            retrieveTopEarnerStats(siteID: siteID,
                                   timeRange: timeRange,
                                   earliestDateToInclude: earliestDateToInclude,
                                   latestDateToInclude: latestDateToInclude,
                                   quantity: quantity,
                                   forceRefresh: forceRefresh,
                                   saveInStorage: saveInStorage,
                                   onCompletion: onCompletion)
        case .retrieveSiteSummaryStats(let siteID,
                                       let siteTimezone,
                                       let period,
                                       let quantity,
                                       let latestDateToInclude,
                                       let saveInStorage,
                                       let onCompletion):
            retrieveSiteSummaryStats(siteID: siteID,
                                     siteTimezone: siteTimezone,
                                     period: period,
                                     quantity: quantity,
                                     latestDateToInclude: latestDateToInclude,
                                     saveInStorage: saveInStorage,
                                     onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension StatsStoreV4 {
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
                       forceRefresh: Bool,
                       onCompletion: @escaping (Result<Void, Error>) -> Void) {
        orderStatsRemote.loadOrderStats(for: siteID,
                                        unit: timeRange.intervalGranularity,
                                        earliestDateToInclude: earliestDateToInclude,
                                        latestDateToInclude: latestDateToInclude,
                                        quantity: quantity,
                                        forceRefresh: forceRefresh) { [weak self] result in
            switch result {
            case .success(let orderStatsV4):
                self?.upsertStoredOrderStats(readOnlyStats: orderStatsV4, timeRange: timeRange)
                onCompletion(.success(()))
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }

    /// Retrieves the order stats for the provided siteID, and time range, without saving them to the Storage layer.
    ///
    func retrieveCustomStats(siteID: Int64,
                             unit: StatsGranularityV4,
                             earliestDateToInclude: Date,
                             latestDateToInclude: Date,
                             quantity: Int,
                             forceRefresh: Bool,
                             onCompletion: @escaping (Result<OrderStatsV4, Error>) -> Void) {
        orderStatsRemote.loadOrderStats(for: siteID,
                                        unit: unit,
                                        earliestDateToInclude: earliestDateToInclude,
                                        latestDateToInclude: latestDateToInclude,
                                        quantity: quantity,
                                        forceRefresh: forceRefresh,
                                        completion: onCompletion)
    }

    /// Retrieves the site visit stats associated with the provided Site ID (if any!).
    ///
    func retrieveSiteVisitStats(siteID: Int64,
                                siteTimezone: TimeZone,
                                timeRange: StatsTimeRangeV4,
                                latestDateToInclude: Date,
                                onCompletion: @escaping (Result<Void, Error>) -> Void) {

        let quantity = timeRange.siteVisitStatsQuantity(date: latestDateToInclude, siteTimezone: siteTimezone)

        siteStatsRemote.loadSiteVisitorStats(for: siteID,
                                    siteTimezone: siteTimezone,
                                    unit: timeRange.siteVisitStatsGranularity,
                                    latestDateToInclude: latestDateToInclude,
                                    quantity: quantity) { [weak self] result in
            switch result {
            case .success(let siteVisitStats):
                self?.upsertStoredSiteVisitStats(readOnlyStats: siteVisitStats, timeRange: timeRange)
                onCompletion(.success(()))
            case .failure(let error):
                onCompletion(.failure(SiteStatsStoreError(error: error)))
            }
        }
    }

    /// Retrieves the site summary stats for the provided site ID, period(s), and date.
    /// Conditionally saves them to storage, if a single period is retrieved.
    ///
    func retrieveSiteSummaryStats(siteID: Int64,
                                  siteTimezone: TimeZone,
                                  period: StatGranularity,
                                  quantity: Int,
                                  latestDateToInclude: Date,
                                  saveInStorage: Bool,
                                  onCompletion: @escaping (Result<SiteSummaryStats, Error>) -> Void) {
        if quantity == 1 {
            siteStatsRemote.loadSiteSummaryStats(for: siteID,
                                                 siteTimezone: siteTimezone,
                                                 period: period,
                                                 includingDate: latestDateToInclude) { [weak self] result in
                switch result {
                case .success(let siteSummaryStats):
                    if saveInStorage {
                        self?.upsertStoredSiteSummaryStats(readOnlyStats: siteSummaryStats)
                    }
                    onCompletion(.success(siteSummaryStats))
                case .failure(let error):
                    onCompletion(.failure(SiteStatsStoreError(error: error)))
                }
            }
        } else {
            // If we are not fetching stats for a single period, we need to summarize the stats manually.
            // The remote summary stats endpoint only retrieves visitor stats for a single period.
            // We should only do this for periods of a month or greater; otherwise the visitor total is inaccurate.
            // See: pe5uwI-5c-p2
            siteStatsRemote.loadSiteVisitorStats(for: siteID,
                                                 siteTimezone: siteTimezone,
                                                 unit: period,
                                                 latestDateToInclude: latestDateToInclude,
                                                 quantity: quantity) { result in
                switch result {
                case .success(let siteVisitStats):
                    let totalViews = siteVisitStats.items?.map({ $0.views }).reduce(0, +) ?? 0
                    let totalVisitors = siteVisitStats.items?.map({ $0.visitors }).reduce(0, +) ?? 0
                    let summaryStats = SiteSummaryStats(siteID: siteID,
                                                        date: siteVisitStats.date,
                                                        period: siteVisitStats.granularity,
                                                        visitors: totalVisitors,
                                                        views: totalViews)
                    onCompletion(.success(summaryStats))
                case .failure(let error):
                    onCompletion(.failure(SiteStatsStoreError(error: error)))
                }
            }
        }
    }

    /// Retrieves the top earner stats associated with the provided Site ID (if any!).
    ///  Saves to storage if required,
    ///
    func retrieveTopEarnerStats(siteID: Int64,
                                timeRange: StatsTimeRangeV4,
                                earliestDateToInclude: Date,
                                latestDateToInclude: Date,
                                quantity: Int,
                                forceRefresh: Bool,
                                saveInStorage: Bool,
                                onCompletion: @escaping (Result<TopEarnerStats, Error>) -> Void) {
        Task { @MainActor in
            do {
                let topEarnersStats = try await loadTopEarnerStats(siteID: siteID,
                                                                   timeRange: timeRange,
                                                                   earliestDateToInclude: earliestDateToInclude,
                                                                   latestDateToInclude: latestDateToInclude,
                                                                   quantity: quantity,
                                                                   forceRefresh: forceRefresh)
                if saveInStorage {
                    upsertStoredTopEarnerStats(readOnlyStats: topEarnersStats)
                }
                onCompletion(.success(topEarnersStats))
            } catch {
                guard let error = error as? DotcomError, error == .noRestRoute else {
                    return onCompletion(.failure(error))
                }

                do {
                    let topEarnersStats = try await loadTopEarnerStatsWithDeprecatedAPI(siteID: siteID,
                                                                                        timeRange: timeRange,
                                                                                        earliestDateToInclude: earliestDateToInclude,
                                                                                        latestDateToInclude: latestDateToInclude,
                                                                                        quantity: quantity,
                                                                                        forceRefresh: forceRefresh)
                    if saveInStorage {
                        upsertStoredTopEarnerStats(readOnlyStats: topEarnersStats)
                    }
                    onCompletion(.success(topEarnersStats))
                } catch {
                    onCompletion(.failure(error))
                }
            }
        }
    }

    @MainActor
    func loadTopEarnerStats(siteID: Int64,
                            timeRange: StatsTimeRangeV4,
                            earliestDateToInclude: Date,
                            latestDateToInclude: Date,
                            quantity: Int,
                            forceRefresh: Bool) async throws -> TopEarnerStats {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<TopEarnerStats, Error>) -> Void in
            let dateFormatter = DateFormatter.Defaults.iso8601WithoutTimeZone
            let earliestDate = dateFormatter.string(from: earliestDateToInclude)
            let latestDate = dateFormatter.string(from: latestDateToInclude)
            leaderboardsRemote.loadLeaderboards(for: siteID,
                                                unit: timeRange.leaderboardsGranularity,
                                                earliestDateToInclude: earliestDate,
                                                latestDateToInclude: latestDate,
                                                quantity: quantity,
                                                forceRefresh: forceRefresh) { [weak self] result in
                guard let self = self else {
                    return
                }

                switch result {
                case .success(let leaderboards):
                    self.convertLeaderboardsIntoTopEarners(siteID: siteID,
                                                           granularity: timeRange.topEarnerStatsGranularity,
                                                           date: latestDateToInclude,
                                                           leaderboards: leaderboards,
                                                           quantity: quantity) { result in
                        continuation.resume(with: result)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    @MainActor
    func loadTopEarnerStatsWithDeprecatedAPI(siteID: Int64,
                                             timeRange: StatsTimeRangeV4,
                                             earliestDateToInclude: Date,
                                             latestDateToInclude: Date,
                                             quantity: Int,
                                             forceRefresh: Bool) async throws -> TopEarnerStats {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<TopEarnerStats, Error>) -> Void in
            let dateFormatter = DateFormatter.Defaults.iso8601WithoutTimeZone
            let earliestDate = dateFormatter.string(from: earliestDateToInclude)
            let latestDate = dateFormatter.string(from: latestDateToInclude)
            leaderboardsRemote.loadLeaderboardsDeprecated(for: siteID,
                                                          unit: timeRange.leaderboardsGranularity,
                                                          earliestDateToInclude: earliestDate,
                                                          latestDateToInclude: latestDate,
                                                          quantity: quantity,
                                                          forceRefresh: forceRefresh) { [weak self] result in
                guard let self = self else {
                    return
                }

                switch result {
                case .success(let leaderboards):
                    self.convertLeaderboardsIntoTopEarners(siteID: siteID,
                                                           granularity: timeRange.topEarnerStatsGranularity,
                                                           date: latestDateToInclude,
                                                           leaderboards: leaderboards,
                                                           quantity: quantity) { result in
                        continuation.resume(with: result)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
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
    func upsertStoredSiteVisitStats(readOnlyStats: Networking.SiteVisitStats, timeRange: StatsTimeRangeV4) {
        assert(Thread.isMainThread)

        let storage = storageManager.viewStorage
        let storageSiteVisitStats = storage.loadSiteVisitStats(
            granularity: readOnlyStats.granularity.rawValue, timeRange: timeRange.rawValue) ?? storage.insertNewObject(ofType: Storage.SiteVisitStats.self)
        storageSiteVisitStats.update(with: readOnlyStats)
        storageSiteVisitStats.timeRange = timeRange.rawValue
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

// MARK: Site summary stats
extension StatsStoreV4 {
    /// Updates (OR Inserts) the specified ReadOnly SiteSummaryStats Entity into the Storage Layer.
    ///
    func upsertStoredSiteSummaryStats(readOnlyStats: Networking.SiteSummaryStats) {
        assert(Thread.isMainThread)

        let storage = storageManager.viewStorage
        let storageSiteSummaryStats = storage.loadSiteSummaryStats(date: readOnlyStats.date, period: readOnlyStats.period.rawValue)
            ?? storage.insertNewObject(ofType: Storage.SiteSummaryStats.self)
        storageSiteSummaryStats.update(with: readOnlyStats)
        storage.saveIfNeeded()
    }
}

// MARK: Convert Leaderboard into TopEarnerStats
//
private extension StatsStoreV4 {

    /// Converts a top-product `leaderboard` into a `StatsTopEarner`
    /// Since  a `leaderboard` does not contain the necessary product information, this method fetches the related product before starting the conversion.
    ///
    func convertLeaderboardsIntoTopEarners(siteID: Int64,
                                           granularity: StatGranularity,
                                           date: Date,
                                           leaderboards: [Leaderboard],
                                           quantity: Int,
                                           onCompletion: @escaping (Result<TopEarnerStats, Error>) -> Void) {

        // Find the top products leaderboard by its ID
        guard let topProducts = leaderboards.first(where: { $0.id == Constants.topProductsID }) else {
            onCompletion(.failure(StatsStoreV4Error.missingTopProducts))
            return
        }

        // Make sure we have all the necessary product data before converting and storing top earners.
        loadProducts(for: topProducts, siteID: siteID) { [weak self] topProductsResult in
            guard let self = self else { return }

            switch topProductsResult {
            case .success(let products):
                let topEarners = self.mergeTopProductsAndStoredProductsIntoTopEarners(siteID: siteID,
                                                                                      granularity: granularity,
                                                                                      date: date,
                                                                                      topProducts: topProducts,
                                                                                      storedProducts: products,
                                                                                      quantityLimit: quantity)
                onCompletion(.success((topEarners)))
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }

    /// Loads product objects that relates to the top products on a `leaderboard`
    /// If product objects can't be found in the storage layer, they will be fetched from the remote layer.
    ///
    func loadProducts(for topProducts: Leaderboard, siteID: Int64, completion: @escaping (Result<[Product], Error>) -> Void) {

        // Workout if we have stored all products that relate to the given leaderboard
        let topProductIDs = LeaderboardStatsConverter.topProductsIDs(from: topProducts)
        let topStoredProducts = loadStoredProducts(siteID: siteID, productIDs: topProductIDs)
        let missingProductsIDs = LeaderboardStatsConverter.missingProductsIDs(from: topProducts, in: topStoredProducts)

        // Return if we have all the products that we need
        guard !missingProductsIDs.isEmpty else {
            completion(.success(topStoredProducts))
            return
        }

        // Fetch the products that we have not downloaded and stored yet
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
    func loadStoredProducts(siteID: Int64, productIDs: [Int64] ) -> [Networking.Product] {
        let products = storageManager.viewStorage.loadProducts(siteID: siteID, productsIDs: productIDs)
        return products.map { $0.toReadOnly() }
    }

    /// Merges a top-product leaderboard with an array of stored products into  a `TopEarnerStats` object
    ///
    func mergeTopProductsAndStoredProductsIntoTopEarners(siteID: Int64,
                                                         granularity: StatGranularity,
                                                         date: Date,
                                                         topProducts: Leaderboard,
                                                         storedProducts: [Product],
                                                         quantityLimit: Int) -> TopEarnerStats {
        let statsDate = Self.buildDateString(from: date, with: granularity)
        let statsItems = LeaderboardStatsConverter.topEarnerStatsItems(from: topProducts, using: storedProducts)
        return TopEarnerStats(siteID: siteID,
                              date: statsDate,
                              granularity: granularity,
                              limit: String(quantityLimit),
                              items: statsItems)
    }
}

// MARK: - Public Helpers
//
public extension StatsStoreV4 {

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

// MARK: - Constants!
//
private extension StatsStoreV4 {

    enum Constants {
        /// ID of top products section in leaderboards API
        ///
        static let topProductsID = "products"
    }
}

// MARK: Errors
//
public enum StatsStoreV4Error: Error {
    case missingTopProducts
}

/// An error that occurs while fetching site visit stats.
///
/// - noPermission: the user has no permission to view site stats.
/// - statsModuleDisabled: Jetpack site stats module is disabled for the site.
/// - unknown: other error cases.
///
public enum SiteStatsStoreError: Error {
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
