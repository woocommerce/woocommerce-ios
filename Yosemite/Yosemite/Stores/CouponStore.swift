import Foundation
import Networking
import Storage

// MARK: - CouponStore
//
public final class CouponStore: Store {
    private let remote: CouponsRemoteProtocol

    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.writerDerivedStorage
    }()

    init(dispatcher: Dispatcher,
         storageManager: StorageManagerType,
         network: Network,
         remote: CouponsRemoteProtocol) {
        self.remote = remote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Initialize a new CouponStore
    /// - Parameters:
    ///   - dispatcher: The dispatcher used to subscribe to `CouponActions`.
    ///   - storageManager: The storage layer used to store and retrieve persisted coupons.
    ///   - network: The network layer used to fetch Coupons
    ///
    public override convenience init(dispatcher: Dispatcher,
                                     storageManager: StorageManagerType,
                                     network: Network) {
        self.init(dispatcher: dispatcher,
                  storageManager: storageManager,
                  network: network,
                  remote: CouponsRemote(network: network))
    }

    // MARK: - Actions

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: CouponAction.self)
    }

    /// Receives and executes Actions.
    /// - Parameters:
    ///   - action: An action to handle. Must be a `CouponAction`
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? CouponAction else {
            assertionFailure("CouponStore received an unsupported action")
            return
        }

        switch action {
        case .synchronizeCoupons(let siteID, let siteURL, let pageNumber, let pageSize, let onCompletion):
            synchronizeCoupons(siteID: siteID,
                               siteURL: siteURL,
                               pageNumber: pageNumber,
                               pageSize: pageSize,
                               onCompletion: onCompletion)
        case .deleteCoupon(let siteID, let siteURL, let couponID, let onCompletion):
            deleteCoupon(siteID: siteID, siteURL: siteURL, couponID: couponID, onCompletion: onCompletion)
        case .updateCoupon(let coupon, let siteURL, let siteTimezone, let onCompletion):
            updateCoupon(coupon, siteURL: siteURL, siteTimezone: siteTimezone, onCompletion: onCompletion)
        case .createCoupon(let coupon, let siteURL, let siteTimezone, let onCompletion):
            createCoupon(coupon, siteURL: siteURL, siteTimezone: siteTimezone, onCompletion: onCompletion)
        case .loadCouponReport(let siteID, let siteURL, let couponID, let startDate, let onCompletion):
            loadCouponReport(siteID: siteID, siteURL: siteURL, couponID: couponID, startDate: startDate, onCompletion: onCompletion)
        case .searchCoupons(let siteID, let siteURL, let keyword, let pageNumber, let pageSize, let onCompletion):
            searchCoupons(siteID: siteID,
                          siteURL: siteURL,
                          keyword: keyword,
                          pageNumber: pageNumber,
                          pageSize: pageSize,
                          onCompletion: onCompletion)
        case .retrieveCoupon(let siteID, let siteURL, let couponID, let onCompletion):
            retrieveCoupon(siteID: siteID, siteURL: siteURL, couponID: couponID, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services
//
private extension CouponStore {

    /// Synchronizes coupons from a Site with what is persisted in the storage layer.
    /// A successful sync of the first page will delete all coupons for the specified site from
    /// storage, in order to reflect deletions made on other devices.
    ///
    /// - Parameters:
    ///   - siteId: The site to synchronizes coupons for.
    ///   - siteURL: Address of the site to fetch coupons for.
    ///   - pageNumber: Page number of coupons to fetch from the API
    ///   - pageSize: Number of coupons per page to fetch from the API
    ///   - onCompletion: Closure to call after sychronizing is complete. Called on the main thread.
    ///   - result: `.success(hasNextPage: Bool)` or `.failure(error: Error)`
    ///
    func synchronizeCoupons(siteID: Int64,
                            siteURL: String,
                            pageNumber: Int,
                            pageSize: Int,
                            onCompletion: @escaping (_ result: Result<Bool, Error>) -> Void) {
        remote.loadAllCoupons(for: siteID,
                              siteURL: siteURL,
                              pageNumber: pageNumber,
                              pageSize: pageSize) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                onCompletion(.failure(error))

            case .success(let coupons):
                let shouldClearData = pageNumber == Default.firstPageNumber
                let hasNextPage = coupons.count == pageSize
                self.upsertStoredCouponsInBackground(readOnlyCoupons: coupons,
                                                     siteID: siteID,
                                                     shouldClearExistingCoupons: shouldClearData) {
                    onCompletion(.success(hasNextPage))
                }
            }
        }
    }

    /// Deletes a coupon from a Site with what is persisted in the storage layer.
    /// After the API request succeeds, the stored coupon should be removed from the local storage.
    /// - Parameters:
    ///   - siteID: The site that the deleted coupon belongs to.
    ///   - siteURL: Address of the site that the coupon belongs to.
    ///   - couponID: The ID of the coupon to be deleted.
    ///   - onCompletion: Closure to call after deletion is complete. Called on the main thread.
    ///
    func deleteCoupon(siteID: Int64, siteURL: String, couponID: Int64, onCompletion: @escaping (Result<Void, Error>) -> Void) {
        remote.deleteCoupon(for: siteID, siteURL: siteURL, couponID: couponID) { [weak self] result in
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
    ///   - siteURL: Address of the site that the coupon belongs to.
    ///   - siteTimezone: the timezone configured on the site (also know as local time of the site).
    ///   - onCompletion: Closure to call after update is complete. Called on the main thread.
    ///
    func updateCoupon(_ coupon: Coupon,
                      siteURL: String,
                      siteTimezone: TimeZone? = nil,
                      onCompletion: @escaping (Result<Coupon, Error>) -> Void) {
        remote.updateCoupon(coupon, siteURL: siteURL, siteTimezone: siteTimezone) { [weak self] result in
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
    ///   - siteURL: Address of the site to create the coupon for.
    ///   - siteTimezone: the timezone configured on the site (also know as local time of the site).
    ///   - onCompletion: Closure to call after creation is complete. Called on the main thread.
    ///
    func createCoupon(_ coupon: Coupon,
                      siteURL: String,
                      siteTimezone: TimeZone? = nil,
                      onCompletion: @escaping (Result<Coupon, Error>) -> Void) {
        remote.createCoupon(coupon, siteURL: siteURL, siteTimezone: siteTimezone) { [weak self] result in
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
    ///     - siteURL: Address of the site from which we'll fetch the analytics report.
    ///     - couponID: ID of the coupon to load the analytics report for.
    ///     - startDate: the start of the date range to load the analytics report for.
    ///     - onCompletion: invoked when the creation finishes.
    ///
    func loadCouponReport(siteID: Int64,
                          siteURL: String,
                          couponID: Int64,
                          startDate: Date,
                          onCompletion: @escaping (Result<CouponReport, Error>) -> Void) {
        remote.loadCouponReport(for: siteID, siteURL: siteURL, couponID: couponID, from: startDate, completion: onCompletion)
    }

    /// Search coupons from a Site that match a specified keyword.
    /// Search results are persisted in the local storage to ensure
    /// good performance for future search of the same keyword.
    ///
    /// - Parameters:
    ///   - siteId: The site to search coupons for.
    ///   - siteURL: address of the site to search coupons for.
    ///   - keyword: The string to match the results with.
    ///   - pageNumber: Page number of coupons to fetch from the API
    ///   - pageSize: Number of coupons per page to fetch from the API
    ///   - onCompletion: Closure to call after the search is complete. Called on the main thread.
    ///
    func searchCoupons(siteID: Int64,
                       siteURL: String,
                       keyword: String,
                       pageNumber: Int,
                       pageSize: Int,
                       onCompletion: @escaping (_ result: Result<Void, Error>) -> Void) {
        remote.searchCoupons(for: siteID,
                             siteURL: siteURL,
                             keyword: keyword,
                             pageNumber: pageNumber,
                             pageSize: pageSize) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                onCompletion(.failure(error))
            case .success(let coupons):
                self.upsertSearchResultsInBackground(siteID: siteID,
                                                     keyword: keyword,
                                                     readOnlyCoupons: coupons) {
                    onCompletion(.success(()))
                }
            }
        }
    }

    /// Retrieve a coupon from a Site given.
    /// The fetched coupon is persisted to the local storage.
    ///
    /// - Parameters:
    ///   - siteID: The site to retrieve the coupon for.
    ///   - siteURL: Address of the site that the coupon belongs to.
    ///   - couponID: ID of the coupon to be retrieved.
    ///   - onCompletion: Closure to call upon completion. Called on the main thread.
    ///
    func retrieveCoupon(siteID: Int64,
                        siteURL: String,
                        couponID: Int64,
                        onCompletion: @escaping (_ result: Result<Coupon, Error>) -> Void) {
        remote.retrieveCoupon(for: siteID,
                              siteURL: siteURL,
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
}


// MARK: - Storage: Coupon
//
private extension CouponStore {

    /// Updates or Inserts specified Coupon Entities in a background thread
    /// `onCompletion` will be called on the main thread.
    ///
    func upsertStoredCouponsInBackground(readOnlyCoupons: [Networking.Coupon],
                                         siteID: Int64,
                                         shouldClearExistingCoupons: Bool = false,
                                         onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform { [weak self] in
            guard let self = self else { return }
            if shouldClearExistingCoupons {
                derivedStorage.deleteCoupons(siteID: siteID)
            }
            self.upsertStoredCoupons(readOnlyCoupons: readOnlyCoupons,
                                      in: derivedStorage,
                                      siteID: siteID)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Updates or Inserts the specified Coupon entities
    ///
    func upsertStoredCoupons(readOnlyCoupons: [Networking.Coupon],
                             in storage: StorageType,
                             siteID: Int64) {
        for coupon in readOnlyCoupons {
            let storageCoupon: Storage.Coupon = {
                if let storedCoupon = storage.loadCoupon(siteID: siteID,
                                                         couponID: coupon.couponID) {
                    return storedCoupon
                }
                return storage.insertNewObject(ofType: Storage.Coupon.self)
            }()

            storageCoupon.update(with: coupon)
        }
    }

    /// Deletes the Storage.Coupon with the specified `siteID` and `couponID` in a background thread.
    /// Triggers `onCompletion` on the main thread when done.
    ///
    func deleteStoredCoupon(siteID: Int64, couponID: Int64, onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform {
            derivedStorage.deleteCoupon(siteID: siteID, couponID: couponID)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Upserts the Coupons, and associates them to the SearchResults Entity (in Background)
    ///
    func upsertSearchResultsInBackground(siteID: Int64, keyword: String, readOnlyCoupons: [Networking.Coupon], onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform { [weak self] in
            self?.upsertStoredCoupons(readOnlyCoupons: readOnlyCoupons, in: derivedStorage, siteID: siteID)
            self?.upsertStoredResults(siteID: siteID, keyword: keyword, readOnlyCoupons: readOnlyCoupons, in: derivedStorage)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Upserts the Coupons, and associates them to the Search Results Entity (in the specified Storage)
    ///
    func upsertStoredResults(siteID: Int64, keyword: String, readOnlyCoupons: [Networking.Coupon], in storage: StorageType) {
        let searchResult = storage.loadCouponSearchResult(keyword: keyword) ?? storage.insertNewObject(ofType: Storage.CouponSearchResult.self)
        searchResult.keyword = keyword

        for coupon in readOnlyCoupons {
            guard let storedCoupon = storage.loadCoupon(siteID: siteID, couponID: coupon.couponID) else {
                continue
            }

            storedCoupon.addToSearchResults(searchResult)
        }
    }
}

public enum CouponError: Error {
    case unexpectedCouponDeleted
}
