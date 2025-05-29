import Foundation
import class Networking.ProductsRemote
import class Networking.ProductVariationsRemote
import class Networking.AlamofireNetwork
import class Networking.WebhooksRemote

public protocol PointOfSaleItemFetchStrategyFactoryProtocol {
    var defaultStrategy: PointOfSalePurchasableItemFetchStrategy { get }

    func searchStrategy(searchTerm: String,
                        analytics: POSSearchAnalyticsTracking) -> PointOfSalePurchasableItemFetchStrategy

    func popularStrategy(pageSize: Int) -> PointOfSalePurchasableItemFetchStrategy
}

public final class PointOfSaleItemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactoryProtocol {
    private let siteID: Int64
    private let productsRemote: ProductsRemote
    private let variationsRemote: ProductVariationsRemote

    public init(siteID: Int64,
                credentials: Credentials?) {
        self.siteID = siteID
        let network = AlamofireNetwork(credentials: credentials)
        self.productsRemote = ProductsRemote(network: network)
        self.variationsRemote = ProductVariationsRemote(network: network)

        let hook = WebhooksRemote(network: network)
        let payloadURLString = ProcessInfo.processInfo.environment["webhook-payload-url"] ?? ""
        guard let payloadURL = URL(string: payloadURLString) else {
            fatalError()
        }
        Task {
            try await hook.createWebhook(for: siteID, topic: "product.updated", deliveryPayloadURL: payloadURL)
        }
    }

    public var defaultStrategy: PointOfSalePurchasableItemFetchStrategy {
        PointOfSaleDefaultPurchasableItemFetchStrategy(siteID: siteID,
                                                       productsRemote: productsRemote,
                                                       variationsRemote: variationsRemote)
    }
    public func searchStrategy(searchTerm: String,
                               analytics: POSSearchAnalyticsTracking) -> PointOfSalePurchasableItemFetchStrategy {
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

    public var defaultStrategy: PointOfSalePurchasableItemFetchStrategy {
        fixedStrategy
    }

    public func searchStrategy(searchTerm: String,
                               analytics: POSSearchAnalyticsTracking) -> PointOfSalePurchasableItemFetchStrategy {
        fixedStrategy
    }

    public func popularStrategy(pageSize: Int) -> PointOfSalePurchasableItemFetchStrategy {
        fixedStrategy
    }
}
