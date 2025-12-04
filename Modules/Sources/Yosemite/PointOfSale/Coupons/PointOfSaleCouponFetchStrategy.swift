import Foundation
import struct Networking.PagedItems
import class WooFoundation.CurrencySettings
import protocol Storage.StorageManagerType

public protocol PointOfSaleCouponFetchStrategy {
    func fetchCoupons(pageNumber: Int) async throws -> PagedItems<POSItem>
    func fetchLocalCoupons() async throws -> [POSItem]
    /// The debouncing strategy to use for search input.
    /// Default is `.immediate` (no debouncing) for non-search strategies.
    var debounceStrategy: SearchDebounceStrategy { get }
}

public extension PointOfSaleCouponFetchStrategy {
    /// Default implementation returns `.immediate` for strategies that don't need debouncing
    var debounceStrategy: SearchDebounceStrategy {
        .immediate
    }
}

struct PointOfSaleDefaultCouponFetchStrategy: PointOfSaleCouponFetchStrategy {
    private let siteID: Int64
    private let currencySettings: CurrencySettings
    private let storage: StorageManagerType
    private let couponStoreMethods: CouponStoreMethodsProtocol

    init(siteID: Int64,
         currencySettings: CurrencySettings,
         storage: StorageManagerType,
         couponStoreMethods: CouponStoreMethodsProtocol) {
        self.siteID = siteID
        self.currencySettings = currencySettings
        self.storage = storage
        self.couponStoreMethods = couponStoreMethods
    }

    func fetchCoupons(pageNumber: Int) async throws -> PagedItems<POSItem> {
        // Update local storage with data from the remote
        let hasMorePages = try await syncCouponsFromRemote(pageNumber: pageNumber)
        // Return all local coupons, including updated ones from the remote
        let coupons = await fetchLocalCoupons(limit: nil)
        return .init(items: coupons, hasMorePages: hasMorePages, totalItems: nil)
    }

    /// fetchLocalCoupons provides an array of coupons that are stored locally
    /// It does not accept any sort of pagination
    /// Limited to default page size to match remote results
    func fetchLocalCoupons() async throws -> [POSItem] {
        return await fetchLocalCoupons(limit: Constants.defaultPageSize)
    }
}

private extension PointOfSaleDefaultCouponFetchStrategy {
    /// Syncing local coupons storage with remote
    /// - Parameter pageNumber: Number of page that should be retrieved.
    /// - Returns: True if there are more pages to sync
    func syncCouponsFromRemote(pageNumber: Int) async throws -> Bool {
        return try await couponStoreMethods.synchronizeCoupons(siteID: siteID,
                                                               pageNumber: pageNumber,
                                                               pageSize: Constants.defaultPageSize)
    }

    @MainActor
    func fetchLocalCoupons(limit: Int? = nil) -> [POSItem] {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let resultsController = CouponResultsControllerAdapter(storage: storage, currencySettings: currencySettings)
        return resultsController.fetchCoupons(predicate: predicate, limit: limit)
    }
}

extension PointOfSaleDefaultCouponFetchStrategy {
    enum Constants {
        static let defaultPageSize: Int = 25
    }
}

// MARK: - Search Coupon Strategy

struct PointOfSaleSearchCouponFetchStrategy: PointOfSaleCouponFetchStrategy {
    private let siteID: Int64
    private let couponStoreMethods: CouponStoreMethodsProtocol
    private let storage: StorageManagerType
    private let currencySettings: CurrencySettings
    private let searchTerm: String
    private let analytics: POSItemFetchAnalyticsTracking

    init(siteID: Int64,
         currencySettings: CurrencySettings,
         storage: StorageManagerType,
         couponStoreMethods: CouponStoreMethodsProtocol,
         searchTerm: String,
         analytics: POSItemFetchAnalyticsTracking
    ) {
        self.siteID = siteID
        self.couponStoreMethods = couponStoreMethods
        self.storage = storage
        self.currencySettings = currencySettings
        self.searchTerm = searchTerm
        self.analytics = analytics
    }

    var debounceStrategy: SearchDebounceStrategy {
        // Use smart debouncing for remote coupon search
        // No loading delay threshold - show loading immediately for responsive feel
        .smart()
    }

    func fetchCoupons(pageNumber: Int) async throws -> PagedItems<POSItem> {
        let startTime = Date()
        try await couponStoreMethods.searchCoupons(siteID: siteID,
                                                   keyword: searchTerm,
                                                   pageNumber: pageNumber,
                                                   pageSize: PointOfSaleDefaultCouponFetchStrategy.Constants.defaultPageSize)
        let results = await getSearchResults()

        if pageNumber == 1 {
            let milliseconds = Int(Date().timeIntervalSince(startTime) * Double(MSEC_PER_SEC))
            analytics.trackSearchRemoteResultsFetchComplete(millisecondsSinceRequestSent: milliseconds,
                                                            totalItems: results.count)
        }

        let hasMorePages = results.count == PointOfSaleDefaultCouponFetchStrategy.Constants.defaultPageSize * pageNumber
        return PagedItems(items: results, hasMorePages: hasMorePages, totalItems: nil)
    }

    @MainActor
    private func getSearchResults() -> [POSItem] {
        let sitePredicate = NSPredicate(format: "siteID == %lld", siteID)
        let searchPredicate = NSPredicate(format: "ANY searchResults.keyword = %@", searchTerm)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [sitePredicate] + [searchPredicate])
        let resultsController = CouponResultsControllerAdapter(storage: storage, currencySettings: currencySettings)
        return resultsController.fetchCoupons(predicate: predicate)
    }

    func fetchLocalCoupons() async throws -> [POSItem] {
        // No support for returning local search results
        return []
    }
}

// MARK: - Results Controller

private struct CouponResultsControllerAdapter {
    private let storage: StorageManagerType
    private let currencySettings: CurrencySettings

    init(storage: StorageManagerType, currencySettings: CurrencySettings) {
        self.storage = storage
        self.currencySettings = currencySettings
    }

    func fetchCoupons(predicate: NSPredicate, limit: Int? = nil) -> [POSItem] {
        let descriptor = NSSortDescriptor(keyPath: \StorageCoupon.dateCreated, ascending: false)
        let resultsController = ResultsController<StorageCoupon>(storageManager: storage,
                                                                 matching: predicate,
                                                                 fetchLimit: limit,
                                                                 sortedBy: [descriptor])

        do {
            try resultsController.performFetch()
            let storageCoupons = resultsController.fetchedObjects
            return mapCouponsToPOSItems(coupons: storageCoupons)
        } catch {
            DDLogError("Failed to load coupons from storage: \(error)")
            return []
        }
    }

    private func mapCouponsToPOSItems(coupons: [Coupon]) -> [POSItem] {
        coupons.compactMap { coupon in
                .coupon(POSCoupon(
                    id: POSItemIdentifier(underlyingType: .coupon, itemID: coupon.couponID),
                    code: coupon.code,
                    summary: coupon.summary(currencySettings: currencySettings),
                    dateExpires: coupon.dateExpires
                ))
        }
    }
}
