import protocol Networking.Network
import class Networking.CouponsRemote
import class Networking.AlamofireNetwork
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings
import Storage

public enum PointOfSaleCouponServiceError: Error {
    case couponsLoadingError
    case couponsDisabled
}

public protocol PointOfSaleCouponServiceProtocol {
    func providePointOfSaleCoupons(pageNumber: Int) async throws -> PagedItems<POSItem>
    func enableCoupons() async throws
}

public final class PointOfSaleCouponService: PointOfSaleCouponServiceProtocol {
    private var siteID: Int64
    private let currencyFormatter: CurrencyFormatter
    private let storage: StorageManagerType?
    private let couponStoreMethods: CouponStoreMethodsProtocol
    private let settingsStoreMethods: SettingStoreMethodsProtocol

    init(siteID: Int64,
         currencySettings: CurrencySettings,
         couponStoreMethods: CouponStoreMethodsProtocol,
         settingStoreMethods: SettingStoreMethodsProtocol,
         storage: StorageManagerType) {
        self.siteID = siteID
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

// Temporarily commented out for debugging
//    @MainActor
//    public func providePointOfSaleCoupons(pageNumber: Int) async throws -> PagedItems<POSItem> {
//        let couponsEnabled = await checkStoreCouponSettings()
//        if !couponsEnabled {
//            throw PointOfSaleCouponServiceError.couponsDisabled
//        }
//
//        let coupons = await fetchCouponsFromStorage()
//
//        if !coupons.isEmpty {
//            // Fire-and-forget sync
//            Task.detached {
//                await self.syncCouponsFromRemote(pageNumber: pageNumber)
//            }
//            return .init(items: coupons, hasMorePages: false)
//        } else {
//            // Wait for the sync to complete
//            // Some rename for easyness
//            await syncCouponsFromRemote(pageNumber: pageNumber)
//            let refreshedCoupons = await fetchCouponsFromStorage()
//            return .init(items: refreshedCoupons, hasMorePages: false)
//        }
//    }
    
#warning("Debug")
    @MainActor
    public func providePointOfSaleCoupons(pageNumber: Int) async throws -> PagedItems<POSItem> {
        // Wait for the remote sync to complete, as this will upsert them into storage, then fetch from storage
        // Which means step 1 just assure that they're fetched correctly
        // When we sync coupons we assure to also know if there are more pages that will need sync, and upsert to storage page by page, then we retrieve them from there.
        let hasMorePages = await syncCouponsFromRemote(pageNumber: pageNumber)
        let refreshedCoupons = await fetchCouponsFromStorage()
        return .init(items: refreshedCoupons, hasMorePages: hasMorePages)
    }

    @MainActor
    public func enableCoupons() async throws {
        _ = await withCheckedContinuation { continuation in
            settingsStoreMethods.enableCouponSetting(siteID: siteID) { result in
                switch result {
                case .success:
                    continuation.resume(returning: true)
                case .failure:
                    continuation.resume(returning: false)
                }
            }
        }
    }
}

private extension PointOfSaleCouponService {
    @MainActor
    func fetchCouponsFromStorage() async -> [POSItem] {
        guard let storage = storage else {
            return []
        }

        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let descriptor = NSSortDescriptor(keyPath: \StorageCoupon.dateCreated,
                                          ascending: false)

        let resultsController = ResultsController<StorageCoupon>(storageManager: storage,
                                                                 matching: predicate,
                                                                 sortedBy: [descriptor])

        do {
            try resultsController.performFetch()
            let storageCoupons = resultsController.fetchedObjects
            return mapCouponsToPOSItems(coupons: storageCoupons)
        } catch {
            debugPrint("Failed to load coupons from storage:", error)
            return []
        }
    }

    func mapCouponsToPOSItems(coupons: [Coupon]) -> [POSItem] {
        coupons.compactMap { coupon in
                .coupon(POSCoupon(id: UUID(), code: coupon.code))
        }
    }

    func syncCouponsFromRemote(pageNumber: Int) async -> Bool {
        // TODO: pageSize no need to be exposed here, is set from the remote.
        do {
            let hasMorePages = try await couponStoreMethods.synchronizeCouponsForPOS(siteID: siteID,
                                                        pageNumber: pageNumber, pageSize: 5)
            //Return this result so we know if there are more pages to fetch?
            return hasMorePages
            
        } catch {
            debugPrint(error)
            // TODO: catch properly
            return false
        }
    }

    private func checkStoreCouponSettings() async -> Bool {
        await withCheckedContinuation { continuation in
            settingsStoreMethods.retrieveCouponSetting(siteID: siteID) { result in
                switch result {
                case let .success(isEnabled):
                    continuation.resume(returning: isEnabled)
                case .failure:
                    continuation.resume(returning: false)
                }
            }
        }
    }
}
