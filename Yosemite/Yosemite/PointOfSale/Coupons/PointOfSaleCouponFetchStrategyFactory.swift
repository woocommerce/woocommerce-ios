import Foundation
import class WooFoundation.CurrencySettings
import protocol Storage.StorageManagerType
import class Networking.CouponsRemote
import class Networking.AlamofireNetwork

public struct PointOfSaleCouponFetchStrategyFactory {
    private let siteID: Int64
    private let currencySettings: CurrencySettings
    private let storage: StorageManagerType
    private let couponStoreMethods: CouponStoreMethodsProtocol

    public init(siteID: Int64,
                currencySettings: CurrencySettings,
                credentials: Credentials?,
                storage: StorageManagerType) {
        let network = AlamofireNetwork(credentials: credentials)
        let remote = CouponsRemote(network: network)
        self.siteID = siteID
        self.currencySettings = currencySettings
        self.storage = storage
        self.couponStoreMethods = CouponStoreMethods(storageManager: storage, remote: remote)
    }

    public var defaultStrategy: PointOfSaleDefaultCouponFetchStrategy {
        PointOfSaleDefaultCouponFetchStrategy(siteID: siteID,
                                              currencySettings: currencySettings,
                                              storage: storage,
                                              couponStoreMethods: couponStoreMethods)
    }

    public func searchStrategy(searchTerm: String, analytics: POSItemFetchAnalyticsTracking) -> PointOfSaleSearchCouponFetchStrategy {
        PointOfSaleSearchCouponFetchStrategy(siteID: siteID,
                                             currencySettings: currencySettings,
                                             storage: storage,
                                             couponStoreMethods: couponStoreMethods,
                                             searchTerm: searchTerm,
                                             analytics: analytics)
    }
}
