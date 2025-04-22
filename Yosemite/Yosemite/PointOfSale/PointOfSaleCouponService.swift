import protocol Networking.Network
import class Networking.CouponsRemote
import class Networking.AlamofireNetwork
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings
import Storage

public enum PointOfSaleCouponServiceError: Error {
    case couponsLoadingError
    case couponsDisabled
    case couponsEnablingError
}

public protocol PointOfSaleCouponServiceProtocol {
    func provideLocalPointOfSaleCoupons() async throws -> [POSItem]
    func providePointOfSaleCoupons(pageNumber: Int) async throws -> PagedItems<POSItem>
    func enableCoupons() async throws
}

public final class PointOfSaleCouponService: PointOfSaleCouponServiceProtocol {
    private var siteID: Int64
    private let currencySettings: CurrencySettings
    private let currencyFormatter: CurrencyFormatter
    private let storage: StorageManagerType
    private let couponStoreMethods: CouponStoreMethodsProtocol
    private let settingsStoreMethods: SettingStoreMethodsProtocol

    init(siteID: Int64,
         currencySettings: CurrencySettings,
         couponStoreMethods: CouponStoreMethodsProtocol,
         settingStoreMethods: SettingStoreMethodsProtocol,
         storage: StorageManagerType) {
        self.siteID = siteID
        self.currencySettings = currencySettings
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.storage = storage
        self.couponStoreMethods = couponStoreMethods
        self.settingsStoreMethods = settingStoreMethods
    }

    public convenience init(siteID: Int64,
                            currencySettings: CurrencySettings,
                            credentials: Credentials?,
                            storage: StorageManagerType) {
        let network = AlamofireNetwork(credentials: credentials)
        let remote = CouponsRemote(network: network)
        self.init(siteID: siteID,
                  currencySettings: currencySettings,
                  couponStoreMethods: CouponStoreMethods(storageManager: storage, remote: remote),
                  settingStoreMethods: SettingStoreMethods(storageManager: storage, network: network),
                  storage: storage)
    }

    // Provides an array of coupons that are stored locally
    // It does not accept any sort of pagination
    // Limited to default page size to match remote results
    @MainActor
    public func provideLocalPointOfSaleCoupons() async throws -> [POSItem] {
        return try await provideLocalPointOfSaleCoupons(limit: Constants.defaultPageSize)
    }

    @MainActor
    private func provideLocalPointOfSaleCoupons(limit: Int?) async throws -> [POSItem] {
        let couponsEnabled = try await checkStoreCouponSettings()
        if !couponsEnabled {
            throw PointOfSaleCouponServiceError.couponsDisabled
        }

        return fetchLocalCoupons(limit: limit)
    }

    /// Syncs with the remote and provides all currently loaded coupons.
    /// - Parameter pageNumber: The page number to fetch from the remote.
    /// - Returns: All currently loaded coupons.
    @MainActor
    public func providePointOfSaleCoupons(pageNumber: Int) async throws -> PagedItems<POSItem> {
        do {
            // Update local storage with data from the remote
            let hasMorePages = try await syncCouponsFromRemote(pageNumber: pageNumber)
            // Return all local coupons, including updated ones from the remote
            let coupons = try await provideLocalPointOfSaleCoupons(limit: nil)
            return .init(items: coupons, hasMorePages: hasMorePages)
        } catch {
            if try await checkRemoteStoreCouponSettings() {
                throw error
            } else {
                throw PointOfSaleCouponServiceError.couponsDisabled
            }
        }
    }

    @MainActor
    public func enableCoupons() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            settingsStoreMethods.enableCouponSetting(siteID: siteID) { result in
                switch result {
                case .success:
                    continuation.resume(returning: ())
                case .failure:
                    continuation.resume(throwing: PointOfSaleCouponServiceError.couponsEnablingError)
                }
            }
        }
    }
}

private extension PointOfSaleCouponService {
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
        let now = Date()
        let nonExpiredCoupons = coupons.filter { coupon in
            guard let expirationDate = coupon.dateExpires else { return true }
            return expirationDate >= now
        }

        return nonExpiredCoupons.compactMap { coupon in
                .coupon(POSCoupon(id: UUID(),
                                  code: coupon.code,
                                  summary: coupon.summary(currencySettings: currencySettings)))
        }
    }

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
    private func checkStoreCouponSettings() async throws -> Bool {
        let settingID = Constants.enableCouponsSettingID
        let storageSetting = storage.viewStorage.loadSiteSetting(siteID: siteID, settingID: settingID)

        switch storageSetting?.value {
        case Constants.enableCouponsSettingValue:
            return true
        default:
            return try await checkRemoteStoreCouponSettings()
        }
    }

    private func checkRemoteStoreCouponSettings() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            settingsStoreMethods.retrieveCouponSetting(siteID: siteID) { result in
                switch result {
                case let .success(isEnabled):
                    continuation.resume(returning: isEnabled)
                case .failure:
                    continuation.resume(throwing: PointOfSaleCouponServiceError.couponsLoadingError)
                }
            }
        }
    }
}

private extension PointOfSaleCouponService {
    enum Constants {
        static let defaultPageSize: Int = 25
        static let enableCouponsSettingID: String = "woocommerce_enable_coupons"
        static let enableCouponsSettingValue: String = "yes"
    }
}
