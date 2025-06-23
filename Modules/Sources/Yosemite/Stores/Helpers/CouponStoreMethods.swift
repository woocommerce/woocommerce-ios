import Foundation
import Networking
import Storage

/// CouponStoreMethods extracts functionality of CouponStore that needs be reused within Yosemite
/// CouponStoreMethods is intentionally internal not to be exposed outside the module
///
internal protocol CouponStoreMethodsProtocol {
    func synchronizeCoupons(siteID: Int64,
                            pageNumber: Int,
                            pageSize: Int) async throws -> Bool
    func synchronizeCoupons(siteID: Int64,
                            pageNumber: Int,
                            pageSize: Int,
                            onCompletion: @escaping (Result<Bool, any Error>) -> Void)

    func deleteCoupon(siteID: Int64,
                      couponID: Int64,
                      onCompletion: @escaping (Result<Void, Error>) -> Void)

    func updateCoupon(_ coupon: Coupon,
                      siteTimezone: TimeZone?,
                      onCompletion: @escaping (Result<Coupon, Error>) -> Void)

    func createCoupon(_ coupon: Coupon,
                      siteTimezone: TimeZone?,
                      onCompletion: @escaping (Result<Coupon, Error>) -> Void)

    func loadCouponReport(siteID: Int64,
                          couponID: Int64,
                          startDate: Date,
                          onCompletion: @escaping (Result<CouponReport, Error>) -> Void)

    func loadMostActiveCoupons(siteID: Int64,
                               numberOfCouponsToLoad: Int,
                               timeRange: StatsTimeRangeV4,
                               siteTimezone: TimeZone,
                               onCompletion: @escaping (Result<[CouponReport], Error>) -> Void)

    func searchCoupons(siteID: Int64,
                       keyword: String,
                       pageNumber: Int,
                       pageSize: Int) async throws

    func searchCoupons(siteID: Int64,
                       keyword: String,
                       pageNumber: Int,
                       pageSize: Int,
                       onCompletion: @escaping (Result<Void, any Error>) -> Void)

    func retrieveCoupon(siteID: Int64,
                        couponID: Int64,
                        onCompletion: @escaping (_ result: Result<Coupon, Error>) -> Void)

    func loadCoupons(siteID: Int64,
                     couponIDs: [Int64],
                     onCompletion: @escaping (_ result: Result<[Coupon], Error>) -> Void)

    func validateCouponCode(code: String,
                           siteID: Int64,
                           onCompletion: @escaping (Result<Bool, Error>) -> Void)
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
    ///   - result: `hasNextPage: Bool` or `error: Error`
    ///
    func synchronizeCoupons(siteID: Int64,
                            pageNumber: Int,
                            pageSize: Int) async throws -> Bool {
        let coupons = try await remote.loadAllCoupons(for: siteID,
                                                      pageNumber: pageNumber,
                                                      pageSize: pageSize)
        let shouldClearData = pageNumber == Remote.Default.firstPageNumber
        let hasNextPage = coupons.count == pageSize
        return await withCheckedContinuation { continuation in
            self.upsertStoredCouponsInBackground(readOnlyCoupons: coupons,
                                                 siteID: siteID,
                                                 shouldClearExistingCoupons: shouldClearData) {
                continuation.resume(returning: hasNextPage)
            }
        }
    }


    func synchronizeCoupons(siteID: Int64,
                            pageNumber: Int,
                            pageSize: Int,
                            onCompletion: @escaping (Result<Bool, any Error>) -> Void) {

        Task { @MainActor in
            do {
                let hasMorePages = try await synchronizeCoupons(siteID: siteID,
                                                                pageNumber: pageNumber,
                                                                pageSize: pageSize)
                onCompletion(.success(hasMorePages))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

    /// Deletes a coupon from a Site with what is persisted in the storage layer.
    /// After the API request succeeds, the stored coupon should be removed from the local storage.
    /// - Parameters:
    ///   - siteID: The site that the deleted coupon belongs to.
    ///   - couponID: The ID of the coupon to be deleted.
    ///   - onCompletion: Closure to call after deletion is complete. Called on the main thread.
    ///
    func deleteCoupon(siteID: Int64, couponID: Int64, onCompletion: @escaping (Result<Void, Error>) -> Void) {
        remote.deleteCoupon(for: siteID, couponID: couponID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                onCompletion(.failure(error))
            case .success(let coupon):
                // This is unlikely to happen, but worth checking
                guard coupon.siteID == siteID, coupon.couponID == couponID else {
                    onCompletion(.failure(CouponError.unexpectedCouponDeleted))
                    DDLogError("⛔️ Unexpected coupon: Deleted couponID \(coupon.couponID) for site \(coupon.siteID) " +
                               "while expecting couponID \(couponID) and site \(siteID)")
                    return
                }
                self.deleteStoredCoupon(siteID: siteID, couponID: couponID) {
                    onCompletion(.success(()))
                }
            }
        }
    }

    /// Updates a coupon given its details.
    /// After the API request succeeds, the stored coupon should be updated accordingly.
    /// - Parameters:
    ///   - coupon: The coupon to be updated
    ///   - siteTimezone: the timezone configured on the site (also know as local time of the site).
    ///   - onCompletion: Closure to call after update is complete. Called on the main thread.
    ///
    func updateCoupon(_ coupon: Coupon,
                      siteTimezone: TimeZone? = nil,
                      onCompletion: @escaping (Result<Coupon, Error>) -> Void) {
        remote.updateCoupon(coupon, siteTimezone: siteTimezone) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                onCompletion(.failure(error))
            case .success(let updatedCoupon):
                self.upsertStoredCouponsInBackground(readOnlyCoupons: [updatedCoupon], siteID: updatedCoupon.siteID) {
                    onCompletion(.success(updatedCoupon))
                }
            }
        }
    }

    /// Creates a coupon given its details.
    /// After the API request succeeds, a new stored coupon should be inserted into the local storage.
    /// - Parameters:
    ///   - coupon: The coupon to be created
    ///   - siteTimezone: the timezone configured on the site (also know as local time of the site).
    ///   - onCompletion: Closure to call after creation is complete. Called on the main thread.
    ///
    func createCoupon(_ coupon: Coupon,
                      siteTimezone: TimeZone? = nil,
                      onCompletion: @escaping (Result<Coupon, Error>) -> Void) {
        remote.createCoupon(coupon, siteTimezone: siteTimezone) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                onCompletion(.failure(error))
            case .success(let createdCoupon):
                self.upsertStoredCouponsInBackground(readOnlyCoupons: [createdCoupon], siteID: createdCoupon.siteID) {
                    onCompletion(.success(createdCoupon))
                }
            }
        }
    }

    /// Loads analytics report for a coupon with the specified coupon ID and site ID.
    ///
    /// - Parameters:
    ///     - siteID: ID of the site that the coupon belongs to.
    ///     - couponID: ID of the coupon to load the analytics report for.
    ///     - startDate: the start of the date range to load the analytics report for.
    ///     - onCompletion: invoked when the creation finishes.
    ///
    func loadCouponReport(siteID: Int64, couponID: Int64, startDate: Date, onCompletion: @escaping (Result<CouponReport, Error>) -> Void) {
        remote.loadCouponReport(for: siteID, couponID: couponID, from: startDate, completion: onCompletion)
    }

    /// Loads top 3 most active coupons report within the specified time range and site ID.
    ///
    /// - `siteID`: site ID.
    /// - `numberOfCouponsToLoad`: Number of coupons to load.
    /// - `timeRange`: Time range to fetch report for.
    /// - `siteTimezone`: site's timezone
    /// - `onCompletion`: invoked when the reports are fetched.
    ///
    func loadMostActiveCoupons(siteID: Int64,
                               numberOfCouponsToLoad: Int,
                               timeRange: StatsTimeRangeV4,
                               siteTimezone: TimeZone,
                               onCompletion: @escaping (Result<[CouponReport], Error>) -> Void) {
        let to = timeRange.latestDate(currentDate: Date(), siteTimezone: siteTimezone)
        let from = timeRange.earliestDate(latestDate: to, siteTimezone: siteTimezone)
        remote.loadMostActiveCoupons(for: siteID,
                                     numberOfCouponsToLoad: numberOfCouponsToLoad,
                                     from: from,
                                     to: to,
                                     completion: onCompletion)
    }

    /// Search coupons from a Site that match a specified keyword.
    /// Search results are persisted in the local storage to ensure
    /// good performance for future search of the same keyword.
    ///
    /// - Parameters:
    ///   - siteId: The site to search coupons for.
    ///   - keyword: The string to match the results with.
    ///   - pageNumber: Page number of coupons to fetch from the API
    ///   - pageSize: Number of coupons per page to fetch from the API
    ///
    func searchCoupons(siteID: Int64,
                       keyword: String,
                       pageNumber: Int,
                       pageSize: Int) async throws {
       let coupons = try await remote.searchCoupons(for: siteID,
                             keyword: keyword,
                             pageNumber: pageNumber,
                             pageSize: pageSize)

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) -> Void in
            upsertSearchResultsInBackground(siteID: siteID,
                                            keyword: keyword,
                                            readOnlyCoupons: coupons, onCompletion: {
                continuation.resume(returning: ())
            })
        }
    }

    func searchCoupons(siteID: Int64,
                       keyword: String,
                       pageNumber: Int,
                       pageSize: Int,
                       onCompletion: @escaping (Result<Void, any Error>) -> Void) {
        Task { @MainActor in
            do {
                try await searchCoupons(siteID: siteID,
                                        keyword: keyword,
                                        pageNumber: pageNumber,
                                        pageSize: pageSize)
                onCompletion(.success(()))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

    /// Retrieve a coupon from a Site given.
    /// The fetched coupon is persisted to the local storage.
    ///
    /// - Parameters:
    ///   - siteID: The site to retrieve the coupon for.
    ///   - couponID: ID of the coupon to be retrieved.
    ///   - onCompletion: Closure to call upon completion. Called on the main thread.
    ///
    func retrieveCoupon(siteID: Int64,
                        couponID: Int64,
                        onCompletion: @escaping (_ result: Result<Coupon, Error>) -> Void) {
        remote.retrieveCoupon(for: siteID,
                              couponID: couponID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                onCompletion(.failure(error))
            case .success(let coupon):
                self.upsertStoredCouponsInBackground(readOnlyCoupons: [coupon], siteID: siteID) {
                    onCompletion(.success(coupon))
                }
            }
        }
    }
    /// Loads the coupons for a site given all the coupon IDs
    ///
    /// - `siteID`: the site for which coupons should be fetched.
    /// - `couponIDs`: IDs of the coupons to be retrieved.
    /// - `onCompletion`: invoked upon completion.
    ///
    func loadCoupons(siteID: Int64,
                     couponIDs: [Int64],
                     onCompletion: @escaping (_ result: Result<[Coupon], Error>) -> Void) {
        remote.loadCoupons(for: siteID, by: couponIDs) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                onCompletion(.failure(error))
            case .success(let coupons):
                self.upsertStoredCouponsInBackground(readOnlyCoupons: coupons, siteID: siteID) {
                    onCompletion(.success(coupons))
                }
            }
        }
    }

    func validateCouponCode(code: String, siteID: Int64, onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        Task {
            do {
                let coupons = try await remote.searchCoupons(for: siteID,
                                                             keyword: code,
                                                             pageNumber: Remote.Default.firstPageNumber,
                                                             pageSize: 25)
                onCompletion(.success(coupons.contains(where: { $0.code == code })))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

}

// MARK: - Persistence

private extension CouponStoreMethods {
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
    func upsertStoredCoupons(readOnlyCoupons: [Networking.Coupon],
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
    func upsertStoredResults(siteID: Int64, keyword: String, readOnlyCoupons: [Networking.Coupon], in storage: StorageType) {
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

public enum CouponError: Error {
    case unexpectedCouponDeleted
}
