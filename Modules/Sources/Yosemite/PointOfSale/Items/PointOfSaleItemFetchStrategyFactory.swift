import Foundation
import class Networking.ProductsRemote
import class Networking.ProductVariationsRemote
import class Networking.AlamofireNetwork
import struct Combine.AnyPublisher
import struct NetworkingCore.JetpackSite
import protocol Storage.GRDBManagerProtocol
import class WooFoundation.CurrencySettings

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
    private let itemMapper: PointOfSaleItemMapperProtocol?
    private let isLocalCatalogEnabled: Bool
    private let isFTSSearchEnabled: Bool
    private let posProductsOnlyEnabled: Bool

    public init(siteID: Int64,
                credentials: Credentials?,
                selectedSite: AnyPublisher<JetpackSite?, Never>? = nil,
                appPasswordSupportState: AnyPublisher<Bool, Never>? = nil,
                grdbManager: GRDBManagerProtocol? = nil,
                currencySettings: CurrencySettings,
                itemMapper: PointOfSaleItemMapperProtocol? = nil,
                isLocalCatalogEnabled: Bool = false,
                isFTSSearchEnabled: Bool = false,
                posProductsOnlyEnabled: Bool = false) {
        self.siteID = siteID
        let network = AlamofireNetwork(credentials: credentials,
                                       selectedSite: selectedSite,
                                       appPasswordSupportState: appPasswordSupportState)
        self.productsRemote = ProductsRemote(network: network)
        self.variationsRemote = ProductVariationsRemote(network: network)
        self.grdbManager = grdbManager
        self.itemMapper = itemMapper ?? PointOfSaleItemMapper(currencySettings: currencySettings)
        self.isLocalCatalogEnabled = isLocalCatalogEnabled
        self.isFTSSearchEnabled = isFTSSearchEnabled
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
        guard isLocalCatalogEnabled, let grdbManager = grdbManager else {
            // Remote API search when local catalog is not enabled
            return PointOfSaleSearchPurchasableItemFetchStrategy(siteID: siteID,
                                                                searchTerm: searchTerm,
                                                                productsRemote: productsRemote,
                                                                variationsRemote: variationsRemote,
                                                                analytics: analytics,
                                                                posProductsOnly: posProductsOnlyEnabled)
        }

        if isFTSSearchEnabled, let itemMapper = itemMapper {
            // FTS-based local search (returns mixed products and variations)
            return PointOfSaleLocalSearchPurchasableItemFetchStrategy(siteID: siteID,
                                                                      searchTerm: searchTerm,
                                                                      grdbManager: grdbManager,
                                                                      variationsRemote: variationsRemote,
                                                                      itemMapper: itemMapper,
                                                                      analytics: analytics,
                                                                      posProductsOnly: posProductsOnlyEnabled)
        } else {
            // Legacy LIKE-based local search (products only)
            return PointOfSaleLegacyLocalSearchPurchasableItemFetchStrategy(siteID: siteID,
                                                                            searchTerm: searchTerm,
                                                                            grdbManager: grdbManager,
                                                                            variationsRemote: variationsRemote,
                                                                            analytics: analytics,
                                                                            posProductsOnly: posProductsOnlyEnabled)
        }
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
