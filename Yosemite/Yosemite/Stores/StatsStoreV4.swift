import Foundation
import Networking
import Storage
import WooFoundation

// MARK: - StatsStoreV4
//
public final class StatsStoreV4: Store {
    private let siteStatsRemote: SiteStatsRemote
    private let orderStatsRemote: OrderStatsRemoteV4
    private let productsRemote: ProductsRemote
    private let productsReportsRemote: ProductsReportsRemote
    private let productBundleStatsRemote: ProductBundleStatsRemote
    private let giftCardStatsRemote: GiftCardStatsRemote

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.siteStatsRemote = SiteStatsRemote(network: network)
        self.orderStatsRemote = OrderStatsRemoteV4(network: network)
        self.productsRemote = ProductsRemote(network: network)
        self.productsReportsRemote = ProductsReportsRemote(network: network)
        self.productBundleStatsRemote = ProductBundleStatsRemote(network: network)
        self.giftCardStatsRemote = GiftCardStatsRemote(network: network)
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
                            let timeZone,
                            let earliestDateToInclude,
                            let latestDateToInclude,
                            let quantity,
                            let forceRefresh,
                            let onCompletion):
            retrieveStats(siteID: siteID,
                          timeRange: timeRange,
                          timeZone: timeZone,
                          earliestDateToInclude: earliestDateToInclude,
                          latestDateToInclude: latestDateToInclude,
                          quantity: quantity,
                          forceRefresh: forceRefresh,
                          onCompletion: onCompletion)
        case .retrieveCustomStats(let siteID,
                                  let unit,
                                  let timeZone,
                                  let earliestDateToInclude,
                                  let latestDateToInclude,
                                  let quantity,
                                  let forceRefresh,
                                  let onCompletion):
            retrieveCustomStats(siteID: siteID,
                                unit: unit,
                                timeZone: timeZone,
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
                                     let timeZone,
                                     let earliestDateToInclude,
                                     let latestDateToInclude,
                                     let quantity,
                                     let forceRefresh,
                                     let saveInStorage,
                                     let onCompletion):
            retrieveTopEarnerStats(siteID: siteID,
                                   timeRange: timeRange,
                                   timeZone: timeZone,
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
        case let .retrieveProductBundleStats(siteID, unit, timeZone, earliestDateToInclude, latestDateToInclude, quantity, forceRefresh, onCompletion):
            retrieveProductBundleStats(siteID: siteID,
                                       unit: unit,
                                       timeZone: timeZone,
                                       earliestDateToInclude: earliestDateToInclude,
                                       latestDateToInclude: latestDateToInclude,
                                       quantity: quantity,
                                       forceRefresh: forceRefresh,
                                       onCompletion: onCompletion)
        case let .retrieveTopProductBundles(siteID, timeZone, earliestDateToInclude, latestDateToInclude, quantity, onCompletion):
            retrieveTopProductBundles(siteID: siteID,
                                      timeZone: timeZone,
                                      earliestDateToInclude: earliestDateToInclude,
                                      latestDateToInclude: latestDateToInclude,
                                      quantity: quantity,
                                      onCompletion: onCompletion)
        case let .retrieveUsedGiftCardStats(siteID, unit, timeZone, earliestDateToInclude, latestDateToInclude, quantity, forceRefresh, onCompletion):
            retrieveUsedGiftCardStats(siteID: siteID,
                                      unit: unit,
                                      timeZone: timeZone,
                                      earliestDateToInclude: earliestDateToInclude,
                                      latestDateToInclude: latestDateToInclude,
                                      quantity: quantity,
                                      forceRefresh: forceRefresh,
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
                       timeZone: TimeZone,
                       earliestDateToInclude: Date,
                       latestDateToInclude: Date,
                       quantity: Int,
                       forceRefresh: Bool,
                       onCompletion: @escaping (Result<Void, Error>) -> Void) {
        orderStatsRemote.loadOrderStats(for: siteID,
                                        unit: timeRange.intervalGranularity,
                                        timeZone: timeZone,
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
                             timeZone: TimeZone,
                             earliestDateToInclude: Date,
                             latestDateToInclude: Date,
                             quantity: Int,
                             forceRefresh: Bool,
                             onCompletion: @escaping (Result<OrderStatsV4, Error>) -> Void) {
        orderStatsRemote.loadOrderStats(for: siteID,
                                        unit: unit,
                                        timeZone: timeZone,
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
                                timeZone: TimeZone,
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
                                                                   timeZone: timeZone,
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

    @MainActor
    func loadTopEarnerStats(siteID: Int64,
                            timeRange: StatsTimeRangeV4,
                            timeZone: TimeZone,
                            earliestDateToInclude: Date,
                            latestDateToInclude: Date,
                            quantity: Int,
                            forceRefresh: Bool) async throws -> TopEarnerStats {
        let productsReport = try await productsReportsRemote.loadTopProductsReport(for: siteID,
                                                                                   timeZone: timeZone,
                                                                                   earliestDateToInclude: earliestDateToInclude,
                                                                                   latestDateToInclude: latestDateToInclude,
                                                                                   quantity: quantity)
        return convertProductsReportIntoTopEarners(siteID: siteID,
                                                   timeRange: timeRange,
                                                   date: latestDateToInclude,
                                                   productsReport: productsReport,
                                                   quantity: quantity)
    }

    /// Retrieves the product bundle stats for the provided siteID, and time range, without saving them to the Storage layer.
    ///
    func retrieveProductBundleStats(siteID: Int64,
                                    unit: StatsGranularityV4,
                                    timeZone: TimeZone,
                                    earliestDateToInclude: Date,
                                    latestDateToInclude: Date,
                                    quantity: Int,
                                    forceRefresh: Bool,
                                    onCompletion: @escaping (Result<ProductBundleStats, Error>) -> Void) {
        Task { @MainActor in
            do {
                let bundleStats = try await productBundleStatsRemote.loadProductBundleStats(for: siteID,
                                                                                            unit: unit,
                                                                                            timeZone: timeZone,
                                                                                            earliestDateToInclude: earliestDateToInclude,
                                                                                            latestDateToInclude: latestDateToInclude,
                                                                                            quantity: quantity,
                                                                                            forceRefresh: forceRefresh)
                onCompletion(.success(bundleStats))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

    /// Retrieves the top product bundles for the provided siteID, and time range, without saving them to the Storage layer.
    ///
    func retrieveTopProductBundles(siteID: Int64,
                                   timeZone: TimeZone,
                                   earliestDateToInclude: Date,
                                   latestDateToInclude: Date,
                                   quantity: Int,
                                   onCompletion: @escaping (Result<[ProductsReportItem], Error>) -> Void) {
        Task { @MainActor in
            do {
                let topBundles = try await productBundleStatsRemote.loadTopProductBundlesReport(for: siteID,
                                                                                                timeZone: timeZone,
                                                                                                earliestDateToInclude: earliestDateToInclude,
                                                                                                latestDateToInclude: latestDateToInclude,
                                                                                                quantity: quantity)
                onCompletion(.success(topBundles))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

    /// Retrieves the used gift card stats for the provided siteID, and time range, without saving them to the Storage layer.
    ///
    func retrieveUsedGiftCardStats(siteID: Int64,
                                   unit: StatsGranularityV4,
                                   timeZone: TimeZone,
                                   earliestDateToInclude: Date,
                                   latestDateToInclude: Date,
                                   quantity: Int,
                                   forceRefresh: Bool,
                                   onCompletion: @escaping (Result<GiftCardStats, Error>) -> Void) {
        Task { @MainActor in
            do {
                let giftCardStats = try await giftCardStatsRemote.loadUsedGiftCardStats(for: siteID,
                                                                                        unit: unit,
                                                                                        timeZone: timeZone,
                                                                                        earliestDateToInclude: earliestDateToInclude,
                                                                                        latestDateToInclude: latestDateToInclude,
                                                                                        quantity: quantity,
                                                                                        forceRefresh: forceRefresh)
                onCompletion(.success(giftCardStats))
            } catch {
                onCompletion(.failure(error))
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

// MARK: Convert Products Report into TopEarnerStats
//
private extension StatsStoreV4 {

    /// Converts the `[ProductsReportItem]` list in a Products analytics report into `TopEarnerStats`
    ///
    func convertProductsReportIntoTopEarners(siteID: Int64,
                                             timeRange: StatsTimeRangeV4,
                                             date: Date,
                                             productsReport: [ProductsReportItem],
                                             quantity: Int) -> TopEarnerStats {
        let statsDate = Self.buildDateString(from: date, timeRange: timeRange)
        let statsItems = productsReport.map { product in
            TopEarnerStatsItem(productID: product.productID,
                               productName: product.productName,
                               quantity: product.quantity,
                               total: product.total,
                               currency: "", // TODO: Remove currency https://github.com/woocommerce/woocommerce-ios/issues/2549
                               imageUrl: product.imageUrl)
        }
        return TopEarnerStats(siteID: siteID, date: statsDate, granularity: timeRange.topEarnerStatsGranularity, limit: quantity.description, items: statsItems)
    }
}

// MARK: - Public Helpers
//
public extension StatsStoreV4 {

    /// Converts a Date into the appropriately formatted string based on the `timeRange`
    ///
    static func buildDateString(from date: Date, timeRange: StatsTimeRangeV4) -> String {
        switch timeRange {
        case .today:
            return DateFormatter.Stats.statsDayFormatter.string(from: date)
        case .thisWeek:
            return DateFormatter.Stats.statsWeekFormatter.string(from: date)
        case .thisMonth:
            return DateFormatter.Stats.statsMonthFormatter.string(from: date)
        case .thisYear:
            return DateFormatter.Stats.statsYearFormatter.string(from: date)
        case let .custom(from, to):
            let fromDate = DateFormatter.Stats.statsDayFormatter.string(from: from)
            let toDate = DateFormatter.Stats.statsDayFormatter.string(from: to)
            return "\(fromDate)/\(toDate)"
        }
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
/// - jetpackNotConnected: Jetpack is not connected on the site.
/// - unknown: other error cases.
///
public enum SiteStatsStoreError: Error {
    case statsModuleDisabled
    case noPermission
    case jetpackNotConnected
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
        case .jetpackNotConnected:
            self = .jetpackNotConnected
        default:
            self = .unknown
        }
    }
}
