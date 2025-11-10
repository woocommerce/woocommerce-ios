import Foundation
import class WooFoundation.CurrencySettings
import protocol Storage.StorageManagerType
import class Networking.CouponsRemote
import class Networking.AlamofireNetwork
import struct Combine.AnyPublisher
import struct NetworkingCore.JetpackSite

public protocol PointOfSaleCouponFetchStrategyFactoryProtocol {
    var defaultStrategy: PointOfSaleCouponFetchStrategy { get }
    func searchStrategy(searchTerm: String, analytics: POSItemFetchAnalyticsTracking) -> PointOfSaleCouponFetchStrategy
}

public struct PointOfSaleCouponFetchStrategyFactory: PointOfSaleCouponFetchStrategyFactoryProtocol {
    private let siteID: Int64
    private let currencySettings: CurrencySettings
    private let storage: StorageManagerType
    private let couponStoreMethods: CouponStoreMethodsProtocol

    public init(siteID: Int64,
                currencySettings: CurrencySettings,
                credentials: Credentials?,
                selectedSite: AnyPublisher<JetpackSite?, Never>,
                appPasswordSupportState: AnyPublisher<Bool, Never>,
                storage: StorageManagerType) {
        let network = AlamofireNetwork(credentials: credentials,
                                       selectedSite: selectedSite,
                                       appPasswordSupportState: appPasswordSupportState)
        let remote = CouponsRemote(network: network)
        self.siteID = siteID
        self.currencySettings = currencySettings
        self.storage = storage
        self.couponStoreMethods = CouponStoreMethods(storageManager: storage, remote: remote)
    }

    public var defaultStrategy: PointOfSaleCouponFetchStrategy {
        PointOfSaleDefaultCouponFetchStrategy(siteID: siteID,
                                              currencySettings: currencySettings,
                                              storage: storage,
                                              couponStoreMethods: couponStoreMethods)
    }

    public func searchStrategy(searchTerm: String, analytics: POSItemFetchAnalyticsTracking) -> PointOfSaleCouponFetchStrategy {
        PointOfSaleSearchCouponFetchStrategy(siteID: siteID,
                                             currencySettings: currencySettings,
                                             storage: storage,
                                             couponStoreMethods: couponStoreMethods,
                                             searchTerm: searchTerm,
                                             analytics: analytics)
    }
}
