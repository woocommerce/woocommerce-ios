import Networking
import Storage

/// CouponStoreMethods extracts functionality of CouponStore that needs be reused within Yosemite
/// CouponStoreMethods is intentionally internal not to be exposed outside the module
///
internal protocol CouponStoreMethodsProtocol {
    func synchronizeCoupons(
        siteID: Int64,
        pageNumber: Int,
        pageSize: Int,
        onCompletion: @escaping (_ result: Result<Bool, Error>) -> Void
    )
}

internal class CouponStoreMethods: CouponStoreMethodsProtocol {
    private let remote: CouponsRemoteProtocol
    private let storageManager: StorageManagerType

    init(
        storageManager: StorageManagerType,
        remote: CouponsRemoteProtocol
    ) {
        self.remote = remote
        self.storageManager = storageManager
    }

    /// Synchronizes coupons from a Site with what is persisted in the storage layer.
    /// A successful sync of the first page will delete all coupons for the specified site from
    /// storage, in order to reflect deletions made on other devices.
    ///
    /// - Parameters:
    ///   - siteId: The site to synchronizes coupons for.
    ///   - pageNumber: Page number of coupons to fetch from the API
    ///   - pageSize: Number of coupons per page to fetch from the API
    ///   - onCompletion: Closure to call after sychronizing is complete. Called on the main thread.
    ///   - result: `.success(hasNextPage: Bool)` or `.failure(error: Error)`
    ///
    func synchronizeCoupons(siteID: Int64,
                            pageNumber: Int,
                            pageSize: Int,
                            onCompletion: @escaping (_ result: Result<Bool, Error>) -> Void) {
        remote.loadAllCoupons(for: siteID,
                              pageNumber: pageNumber,
                              pageSize: pageSize) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                onCompletion(.failure(error))

            case .success(let coupons):
                let shouldClearData = pageNumber == Remote.Default.firstPageNumber
                let hasNextPage = coupons.count == pageSize
                self.upsertStoredCouponsInBackground(readOnlyCoupons: coupons,
                                                     siteID: siteID,
                                                     shouldClearExistingCoupons: shouldClearData) {
                    onCompletion(.success(hasNextPage))
                }
            }
        }
    }

    // MARK: - Storage Coupon

    /// Updates or Inserts specified Coupon Entities in a background thread
    /// `onCompletion` will be called on the main thread.
    ///
    func upsertStoredCouponsInBackground(readOnlyCoupons: [Networking.Coupon],
                                         siteID: Int64,
                                         shouldClearExistingCoupons: Bool = false,
                                         onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ [weak self] storage in
            guard let self else { return }
            if shouldClearExistingCoupons {
                storage.deleteCoupons(siteID: siteID)
            }
            upsertStoredCoupons(readOnlyCoupons: readOnlyCoupons,
                                in: storage,
                                siteID: siteID)
        }, completion: onCompletion, on: .main)
    }

    /// Updates or Inserts the specified Coupon entities
    ///
    func deleteStoredCoupon(siteID: Int64, couponID: Int64, onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ storage in
            storage.deleteCoupon(siteID: siteID, couponID: couponID)
        }, completion: onCompletion, on: .main)
    }

    /// Deletes the Storage.Coupon with the specified `siteID` and `couponID` in a background thread.
    /// Triggers `onCompletion` on the main thread when done.
    ///
    private func upsertStoredCoupons(readOnlyCoupons: [Networking.Coupon],
                             in storage: StorageType,
                             siteID: Int64) {
        let storedCoupons = storage.loadCoupons(siteID: siteID, with: readOnlyCoupons.map { $0.couponID })
        for coupon in readOnlyCoupons {
            let storageCoupon: Storage.Coupon = {
                if let storedCoupon = storedCoupons.first(where: { $0.couponID == coupon.couponID }) {
                    return storedCoupon
                }
                return storage.insertNewObject(ofType: Storage.Coupon.self)
            }()

            storageCoupon.update(with: coupon)
        }
    }

    /// Upserts the Coupons, and associates them to the SearchResults Entity (in Background)
    ///
    func upsertSearchResultsInBackground(siteID: Int64, keyword: String, readOnlyCoupons: [Networking.Coupon], onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ [weak self] storage in
            guard let self else { return }
            upsertStoredCoupons(readOnlyCoupons: readOnlyCoupons, in: storage, siteID: siteID)
            upsertStoredResults(siteID: siteID, keyword: keyword, readOnlyCoupons: readOnlyCoupons, in: storage)
        }, completion: onCompletion, on: .main)
    }

    /// Upserts the Coupons, and associates them to the Search Results Entity (in the specified Storage)
    ///
    private func upsertStoredResults(siteID: Int64, keyword: String, readOnlyCoupons: [Networking.Coupon], in storage: StorageType) {
        let searchResult = storage.loadCouponSearchResult(keyword: keyword) ?? storage.insertNewObject(ofType: Storage.CouponSearchResult.self)
        searchResult.keyword = keyword

        let storedCoupons = storage.loadCoupons(siteID: siteID, with: readOnlyCoupons.map { $0.couponID })
        for coupon in readOnlyCoupons {
            guard let storedCoupon = storedCoupons.first(where: { $0.couponID == coupon.couponID }) else {
                continue
            }

            storedCoupon.addToSearchResults(searchResult)
        }
    }
}
