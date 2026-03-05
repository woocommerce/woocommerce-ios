import protocol Networking.Network
import class Networking.CouponsRemote
import class Networking.AlamofireNetwork
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings
import Storage
import enum Alamofire.AFError
import struct Combine.AnyPublisher
import struct NetworkingCore.JetpackSite

public protocol PointOfSaleCouponServiceProtocol {
    func provideLocalPointOfSaleCoupons(fetchStrategy: PointOfSaleCouponFetchStrategy) async throws -> [POSItem]
    func providePointOfSaleCoupons(pageNumber: Int,
                                   fetchStrategy: PointOfSaleCouponFetchStrategy) async throws -> PagedItems<POSItem>
    func enableCoupons() async throws
}

public final class PointOfSaleCouponService: PointOfSaleCouponServiceProtocol {
    private var siteID: Int64
    private let storage: StorageManagerType
    private let settingsStoreMethods: SettingStoreMethodsProtocol
    private let isSiteCIAB: Bool

    init(siteID: Int64,
         currencySettings: CurrencySettings,
         settingStoreMethods: SettingStoreMethodsProtocol,
         storage: StorageManagerType,
         isSiteCIAB: Bool = false) {
        self.siteID = siteID
        self.storage = storage
        self.settingsStoreMethods = settingStoreMethods
        self.isSiteCIAB = isSiteCIAB
    }

    public convenience init(siteID: Int64,
                            currencySettings: CurrencySettings,
                            credentials: Credentials?,
                            selectedSite: AnyPublisher<JetpackSite?, Never>,
                            appPasswordSupportState: AnyPublisher<Bool, Never>,
                            storage: StorageManagerType,
                            isSiteCIAB: Bool = false) {
        let network = AlamofireNetwork(credentials: credentials,
                                       selectedSite: selectedSite,
                                       appPasswordSupportState: appPasswordSupportState)
        self.init(siteID: siteID,
                  currencySettings: currencySettings,
                  settingStoreMethods: SettingStoreMethods(storageManager: storage, network: network),
                  storage: storage,
                  isSiteCIAB: isSiteCIAB)
    }

    @MainActor
    public func provideLocalPointOfSaleCoupons(fetchStrategy: PointOfSaleCouponFetchStrategy) async throws -> [POSItem] {
        let couponsEnabled = try await checkStoreCouponSettings()
        if !couponsEnabled {
            throw PointOfSaleCouponServiceError.couponsDisabled
        }

        return try await fetchStrategy.fetchLocalCoupons()
    }

    /// Syncs with the remote and provides all currently loaded coupons.
    /// - Parameter pageNumber: The page number to fetch from the remote.
    /// - Returns: All currently loaded coupons.
    @MainActor
    public func providePointOfSaleCoupons(pageNumber: Int,
                                          fetchStrategy: PointOfSaleCouponFetchStrategy) async throws -> PagedItems<POSItem> {
        do {
            return try await fetchStrategy.fetchCoupons(pageNumber: pageNumber)
        } catch AFError.explicitlyCancelled {
            throw PointOfSaleCouponServiceError.requestCancelled
        } catch {
            if try await checkRemoteStoreCouponSettings() {
                throw PointOfSaleCouponServiceError.couponsLoadingError(underlyingError: error)
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
                case .failure(let error):
                    continuation.resume(throwing: PointOfSaleCouponServiceError.couponsEnablingError(underlyingError: error))
                }
            }
        }
    }
}

private extension PointOfSaleCouponService {
    @MainActor
    private func checkStoreCouponSettings() async throws -> Bool {
        if isSiteCIAB {
            return true
        }
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
        if isSiteCIAB {
            return true
        }
        return try await withCheckedThrowingContinuation { continuation in
            settingsStoreMethods.retrieveCouponSetting(siteID: siteID) { result in
                switch result {
                case let .success(isEnabled):
                    continuation.resume(returning: isEnabled)
                case .failure(let error):
                    continuation.resume(throwing: PointOfSaleCouponServiceError.couponsLoadingError(underlyingError: error))
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

public enum PointOfSaleCouponServiceError: Error, Equatable {
    case couponsLoadingError(underlyingError: Error)
    case couponsDisabled
    case couponsEnablingError(underlyingError: Error)
    case requestCancelled

    public static func == (lhs: PointOfSaleCouponServiceError, rhs: PointOfSaleCouponServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.couponsDisabled, .couponsDisabled),
             (.couponsEnablingError, .couponsEnablingError),
             (.requestCancelled, .requestCancelled),
            (.couponsLoadingError, .couponsLoadingError):
            return true
        default:
            return false
        }
    }

    public var underlyingError: Error? {
        switch self {
        case .couponsLoadingError(let underlyingError), .couponsEnablingError(let underlyingError):
            return underlyingError
        default:
            return nil
        }
    }
}
