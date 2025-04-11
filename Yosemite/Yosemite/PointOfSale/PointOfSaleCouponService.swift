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
    func provideLocalPointOfSaleCoupons() async throws -> [POSItem]
    func providePointOfSaleCoupons(pageNumber: Int) async throws -> PagedItems<POSItem>
    func enableCoupons() async throws
}

public final class PointOfSaleCouponService: PointOfSaleCouponServiceProtocol {
    private var siteID: Int64
    private let currencySettings: CurrencySettings
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

    // Provides an array of coupons that are stored locally, it does not accept any sort of pagination
    public func provideLocalPointOfSaleCoupons() async throws -> [POSItem] {
        let couponsEnabled = await checkStoreCouponSettings()
        if !couponsEnabled {
            throw PointOfSaleCouponServiceError.couponsDisabled
        }

        let localCoupons = await fetchLocalCoupons()
        return localCoupons.items
    }

    @MainActor
    public func providePointOfSaleCoupons(pageNumber: Int) async throws -> PagedItems<POSItem> {
        await syncCouponsFromRemote(pageNumber: pageNumber)
        let coupons = try await provideLocalPointOfSaleCoupons()
        return .init(items: coupons, hasMorePages: true)
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
    func fetchLocalCoupons() async -> PagedItems<POSItem> {
        guard let storage = storage else {
            return .init(items: [], hasMorePages: false)
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
            let posItems = mapCouponsToPOSItems(coupons: storageCoupons)
            return .init(items: posItems, hasMorePages: true)
        } catch {
            debugPrint("Failed to load coupons from storage:", error)
            return .init(items: [], hasMorePages: false)
        }
    }

    func mapCouponsToPOSItems(coupons: [Coupon]) -> [POSItem] {
        coupons.compactMap { coupon in
                .coupon(POSCoupon(
                    id: UUID(),
                    code: coupon.code,
                    summary: coupon.summary(currencySettings: currencySettings)
                ))
        }
    }

    func syncCouponsFromRemote(pageNumber: Int) async {
        await withCheckedContinuation { continuation in
            couponStoreMethods.synchronizeCoupons(
                siteID: siteID,
                pageNumber: pageNumber,
                pageSize: Constants.defaultPageSize,
                onCompletion: { _ in
                    continuation.resume()
                }
            )
        }
    }

    @MainActor
    private func checkStoreCouponSettings() async -> Bool {
        let settingID = Constants.enableCouponsSettingID
        let storageSetting = storage?.viewStorage.loadSiteSetting(siteID: siteID, settingID: settingID)

        switch storageSetting {
        case let .some(setting):
            if setting.value == Constants.enableCouponsSettingValue {
                return true
            } else {
                return await checkRemoteStoreCouponSettings()
            }
        default:
            return await checkRemoteStoreCouponSettings()
        }
    }

    private func checkRemoteStoreCouponSettings() async -> Bool {
        return await withCheckedContinuation { continuation in
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

private extension PointOfSaleCouponService {
    enum Constants {
        static let defaultPageSize: Int = 25
        static let enableCouponsSettingID: String = "woocommerce_enable_coupons"
        static let enableCouponsSettingValue: String = "yes"
    }
}
