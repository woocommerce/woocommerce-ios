import Foundation
import struct Networking.PagedItems
import class WooFoundation.CurrencySettings
import protocol Storage.StorageManagerType

public protocol PointOfSaleCouponFetchStrategy {
    func fetchCoupons(pageNumber: Int) async throws -> PagedItems<POSItem>
    func fetchLocalCoupons() async throws -> [POSItem]
}

public struct PointOfSaleDefaultCouponFetchStrategy: PointOfSaleCouponFetchStrategy {
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

    public func fetchCoupons(pageNumber: Int) async throws -> PagedItems<POSItem> {
        // Update local storage with data from the remote
        let hasMorePages = try await syncCouponsFromRemote(pageNumber: pageNumber)
        // Return all local coupons, including updated ones from the remote
        let coupons = await fetchLocalCoupons(limit: nil)
        return .init(items: coupons, hasMorePages: hasMorePages)
    }

    /// fetchLocalCoupons provides an array of coupons that are stored locally
    /// It does not accept any sort of pagination
    /// Limited to default page size to match remote results
    public func fetchLocalCoupons() async throws -> [POSItem] {
        return await fetchLocalCoupons(limit: Constants.defaultPageSize)
    }
}

private extension PointOfSaleDefaultCouponFetchStrategy {
    /// Syncing local coupons storage with remote
    /// - Parameter pageNumber: Number of page that should be retrieved.
    /// - Returns: True if there are more pages to sync
    func syncCouponsFromRemote(pageNumber: Int) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            couponStoreMethods.synchronizeCoupons(
                siteID: siteID,
                pageNumber: pageNumber,
                pageSize: Constants.defaultPageSize,
                onCompletion: { result in
                    switch result {
                    case .success(let hasMorePages):
                        continuation.resume(returning: hasMorePages)
                    case .failure:
                        continuation.resume(throwing: PointOfSaleCouponServiceError.couponsLoadingError)
                    }
                }
            )
        }
    }

    @MainActor
    func fetchLocalCoupons(limit: Int? = nil) -> [POSItem] {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let descriptor = NSSortDescriptor(keyPath: \StorageCoupon.dateCreated,
                                          ascending: false)

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

    func mapCouponsToPOSItems(coupons: [Coupon]) -> [POSItem] {
        coupons.compactMap { coupon in
                .coupon(POSCoupon(
                    id: UUID(),
                    code: coupon.code,
                    summary: coupon.summary(currencySettings: currencySettings),
                    dateExpires: coupon.dateExpires
                ))
        }
    }
}

private extension PointOfSaleDefaultCouponFetchStrategy {
    enum Constants {
        static let defaultPageSize: Int = 25
    }
}
