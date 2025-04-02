import Foundation
import class Networking.ProductsRemote
import class Networking.ProductVariationsRemote
import class Networking.AlamofireNetwork

public final class PointOfSaleItemFetchStrategyFactory {
    private let siteID: Int64
    private let productsRemote: ProductsRemote
    private let variationsRemote: ProductVariationsRemote

    public init(siteID: Int64, credentials: Credentials?) {
        self.siteID = siteID
        let network = AlamofireNetwork(credentials: credentials)
        self.productsRemote = ProductsRemote(network: network)
        self.variationsRemote = ProductVariationsRemote(network: network)
    }

    public var defaultStrategy: PointOfSaleDefaultPurchasableItemFetchStrategy {
        PointOfSaleDefaultPurchasableItemFetchStrategy(siteID: siteID,
                                                       productsRemote: productsRemote,
                                                       variationsRemote: variationsRemote)
    }
}
