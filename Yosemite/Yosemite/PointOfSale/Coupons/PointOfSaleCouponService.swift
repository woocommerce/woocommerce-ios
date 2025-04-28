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

    private let strategy: PointOfSaleCouponFetchStrategy

    init(siteID: Int64,
         currencySettings: CurrencySettings,
         couponStoreMethods: CouponStoreMethodsProtocol,
         settingStoreMethods: SettingStoreMethodsProtocol,
         storage: StorageManagerType,
         strategy: PointOfSaleCouponFetchStrategy? = nil) {
        self.siteID = siteID
        self.currencySettings = currencySettings
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.storage = storage
        self.couponStoreMethods = couponStoreMethods
        self.settingsStoreMethods = settingStoreMethods
        self.strategy = strategy ?? PointOfSaleDefaultCouponFetchStrategy(
            siteID: siteID,
            currencySettings: currencySettings,
            storage: storage,
            couponStoreMethods: couponStoreMethods
        )
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

    @MainActor
    public func provideLocalPointOfSaleCoupons() async throws -> [POSItem] {
        let couponsEnabled = try await checkStoreCouponSettings()
        if !couponsEnabled {
            throw PointOfSaleCouponServiceError.couponsDisabled
        }

        return try await strategy.fetchLocalCoupons()
    }

    /// Syncs with the remote and provides all currently loaded coupons.
    /// - Parameter pageNumber: The page number to fetch from the remote.
    /// - Returns: All currently loaded coupons.
    @MainActor
    public func providePointOfSaleCoupons(pageNumber: Int) async throws -> PagedItems<POSItem> {
        do {
            return try await strategy.fetchCoupons(pageNumber: pageNumber)
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
        static let enableCouponsSettingID: String = "woocommerce_enable_coupons"
        static let enableCouponsSettingValue: String = "yes"
    }
}
