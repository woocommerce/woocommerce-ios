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

    public init(siteID: Int64,
                credentials: Credentials?,
                selectedSite: AnyPublisher<JetpackSite?, Never>? = nil,
                appPasswordSupportState: AnyPublisher<Bool, Never>? = nil,
                grdbManager: GRDBManagerProtocol? = nil,
                currencySettings: CurrencySettings,
                itemMapper: PointOfSaleItemMapperProtocol? = nil,
                isLocalCatalogEnabled: Bool = false,
                isFTSSearchEnabled: Bool = false) {
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
    }

    public func defaultStrategy(analytics: POSItemFetchAnalyticsTracking) -> PointOfSalePurchasableItemFetchStrategy {
        PointOfSaleDefaultPurchasableItemFetchStrategy(siteID: siteID,
                                                       productsRemote: productsRemote,
                                                       variationsRemote: variationsRemote,
                                                       analytics: analytics)
    }
    public func searchStrategy(searchTerm: String,
                               analytics: POSItemFetchAnalyticsTracking) -> PointOfSalePurchasableItemFetchStrategy {
        // Use local search if local catalog is enabled and dependencies are available
        // The strategy will use FTS when enabled, or fall back to LIKE-based queries
        if isLocalCatalogEnabled, let grdbManager, let itemMapper {
            return PointOfSaleLocalSearchPurchasableItemFetchStrategy(siteID: siteID,
                                                                      searchTerm: searchTerm,
                                                                      grdbManager: grdbManager,
                                                                      variationsRemote: variationsRemote,
                                                                      itemMapper: itemMapper,
                                                                      analytics: analytics,
                                                                      isFTSSearchEnabled: isFTSSearchEnabled)
        }
        // Fall back to remote API search
        return PointOfSaleSearchPurchasableItemFetchStrategy(siteID: siteID,
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
}
