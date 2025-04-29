import Foundation
import class WooFoundation.CurrencySettings
import protocol Storage.StorageManagerType

public final class PointOfSaleCouponFetchStrategyFactory {
    private let siteID: Int64
    private let currencySettings: CurrencySettings
    private let storage: StorageManagerType
    private let couponStoreMethods: CouponStoreMethodsProtocol

    init(siteID: Int64,
         currencySettings: CurrencySettings,
         storage: StorageManagerType,
         couponStoreMethods: CouponStoreMethodsProtocol) {
        self.siteID = siteID
        self.currencySettings = currencySettings
        self.storage = storage
        self.couponStoreMethods = couponStoreMethods
    }

    public var defaultStrategy: PointOfSaleDefaultCouponFetchStrategy {
        PointOfSaleDefaultCouponFetchStrategy(siteID: siteID,
                                              currencySettings: currencySettings,
                                              storage: storage,
                                              couponStoreMethods: couponStoreMethods)
    }

    public func searchStrategy(searchTerm: String) -> PointOfSaleSearchCouponFetchStrategy {
        PointOfSaleSearchCouponFetchStrategy(siteID: siteID,
                                             currencySettings: currencySettings,
                                             storage: storage,
                                             couponStoreMethods: couponStoreMethods,
                                             searchTerm: searchTerm)
    }
}
