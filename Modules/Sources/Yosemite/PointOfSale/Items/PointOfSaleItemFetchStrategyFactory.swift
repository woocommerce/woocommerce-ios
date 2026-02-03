import Foundation
import class Networking.ProductsRemote
import class Networking.ProductVariationsRemote
import class Networking.AlamofireNetwork
import struct Combine.AnyPublisher
import struct NetworkingCore.JetpackSite
import protocol Storage.GRDBManagerProtocol

public protocol PointOfSaleItemFetchStrategyFactoryProtocol {
    func defaultStrategy(analytics: POSItemFetchAnalyticsTracking) -> PointOfSalePurchasableItemFetchStrategy

    func searchStrategy(searchTerm: String,
                        analytics: POSItemFetchAnalyticsTracking) -> PointOfSalePurchasableItemFetchStrategy
}

public final class PointOfSaleItemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactoryProtocol {
    private let siteID: Int64
    private let productsRemote: ProductsRemote
    private let variationsRemote: ProductVariationsRemote
    private let grdbManager: GRDBManagerProtocol?
    private let isLocalCatalogEnabled: Bool
    private let posProductsOnlyEnabled: Bool

    public init(siteID: Int64,
                credentials: Credentials?,
                selectedSite: AnyPublisher<JetpackSite?, Never>? = nil,
                appPasswordSupportState: AnyPublisher<Bool, Never>? = nil,
                grdbManager: GRDBManagerProtocol? = nil,
                isLocalCatalogEnabled: Bool = false,
                posProductsOnlyEnabled: Bool = false) {
        self.siteID = siteID
        let network = AlamofireNetwork(credentials: credentials,
                                       selectedSite: selectedSite,
                                       appPasswordSupportState: appPasswordSupportState)
        self.productsRemote = ProductsRemote(network: network)
        self.variationsRemote = ProductVariationsRemote(network: network)
        self.grdbManager = grdbManager
        self.isLocalCatalogEnabled = isLocalCatalogEnabled
        self.posProductsOnlyEnabled = posProductsOnlyEnabled
    }

    public func defaultStrategy(analytics: POSItemFetchAnalyticsTracking) -> PointOfSalePurchasableItemFetchStrategy {
        PointOfSaleDefaultPurchasableItemFetchStrategy(siteID: siteID,
                                                       productsRemote: productsRemote,
                                                       variationsRemote: variationsRemote,
                                                       analytics: analytics,
                                                       posProductsOnly: posProductsOnlyEnabled)
    }
    public func searchStrategy(searchTerm: String,
                               analytics: POSItemFetchAnalyticsTracking) -> PointOfSalePurchasableItemFetchStrategy {
        // Use local search if explicitly enabled and GRDB manager is available
        if isLocalCatalogEnabled, let grdbManager = grdbManager {
            return PointOfSaleLocalSearchPurchasableItemFetchStrategy(siteID: siteID,
                                                                      searchTerm: searchTerm,
                                                                      grdbManager: grdbManager,
                                                                      variationsRemote: variationsRemote,
                                                                      analytics: analytics,
                                                                      posProductsOnly: posProductsOnlyEnabled)
        }
        return PointOfSaleSearchPurchasableItemFetchStrategy(siteID: siteID,
                                                            searchTerm: searchTerm,
                                                            productsRemote: productsRemote,
                                                            variationsRemote: variationsRemote,
                                                            analytics: analytics,
                                                            posProductsOnly: posProductsOnlyEnabled)
    }

    public func popularStrategy(pageSize: Int = 10) -> PointOfSalePurchasableItemFetchStrategy {
        PointOfSalePopularPurchasableItemFetchStrategy(siteID: siteID,
                                                       pageSize: pageSize,
                                                       productsRemote: productsRemote,
                                                       variationsRemote: variationsRemote,
                                                       posProductsOnly: posProductsOnlyEnabled)
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
}
