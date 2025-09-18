import Foundation
import class Networking.ProductsRemote
import class Networking.ProductVariationsRemote
import class Networking.AlamofireNetwork
import struct Combine.AnyPublisher
import struct NetworkingCore.JetpackSite

public protocol PointOfSaleItemFetchStrategyFactoryProtocol {
    func defaultStrategy(analytics: POSItemFetchAnalyticsTracking) -> PointOfSalePurchasableItemFetchStrategy

    func searchStrategy(searchTerm: String,
                        analytics: POSItemFetchAnalyticsTracking) -> PointOfSalePurchasableItemFetchStrategy

    func popularStrategy(pageSize: Int) -> PointOfSalePurchasableItemFetchStrategy
}

public final class PointOfSaleItemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactoryProtocol {
    private let siteID: Int64
    private let productsRemote: ProductsRemote
    private let variationsRemote: ProductVariationsRemote

    public init(siteID: Int64,
                credentials: Credentials?,
                selectedSite: AnyPublisher<JetpackSite?, Never>? = nil,
                appPasswordSupportState: AnyPublisher<Bool, Never>? = nil) {
        self.siteID = siteID
        let network = AlamofireNetwork(credentials: credentials,
                                       selectedSite: selectedSite,
                                       appPasswordSupportState: appPasswordSupportState)
        self.productsRemote = ProductsRemote(network: network)
        self.variationsRemote = ProductVariationsRemote(network: network)
    }

    public func defaultStrategy(analytics: POSItemFetchAnalyticsTracking) -> PointOfSalePurchasableItemFetchStrategy {
        PointOfSaleDefaultPurchasableItemFetchStrategy(siteID: siteID,
                                                       productsRemote: productsRemote,
                                                       variationsRemote: variationsRemote,
                                                       analytics: analytics)
    }
    public func searchStrategy(searchTerm: String,
                               analytics: POSItemFetchAnalyticsTracking) -> PointOfSalePurchasableItemFetchStrategy {
        PointOfSaleSearchPurchasableItemFetchStrategy(siteID: siteID,
                                                      searchTerm: searchTerm,
                                                      productsRemote: productsRemote,
                                                      variationsRemote: variationsRemote,
                                                      analytics: analytics)
    }

    public func popularStrategy(pageSize: Int = 10) -> PointOfSalePurchasableItemFetchStrategy {
        PointOfSalePopularPurchasableItemFetchStrategy(siteID: siteID,
                                                       pageSize: pageSize,
                                                       productsRemote: productsRemote,
                                                       variationsRemote: variationsRemote)
    }
}

public final class PointOfSaleFixedItemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactoryProtocol {
    private let fixedStrategy: PointOfSalePurchasableItemFetchStrategy

    public init(fixedStrategy: PointOfSalePurchasableItemFetchStrategy) {
        self.fixedStrategy = fixedStrategy
    }

    public func defaultStrategy(analytics: POSItemFetchAnalyticsTracking) -> PointOfSalePurchasableItemFetchStrategy {
        fixedStrategy
    }

    public func searchStrategy(searchTerm: String,
                               analytics: POSItemFetchAnalyticsTracking) -> PointOfSalePurchasableItemFetchStrategy {
        fixedStrategy
    }

    public func popularStrategy(pageSize: Int) -> PointOfSalePurchasableItemFetchStrategy {
        fixedStrategy
    }
}
