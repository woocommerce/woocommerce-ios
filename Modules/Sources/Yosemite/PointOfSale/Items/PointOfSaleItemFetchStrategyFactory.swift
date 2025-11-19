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

    public init(siteID: Int64,
                credentials: Credentials?,
                selectedSite: AnyPublisher<JetpackSite?, Never>? = nil,
                appPasswordSupportState: AnyPublisher<Bool, Never>? = nil,
                grdbManager: GRDBManagerProtocol? = nil) {
        self.siteID = siteID
        let network = AlamofireNetwork(credentials: credentials,
                                       selectedSite: selectedSite,
                                       appPasswordSupportState: appPasswordSupportState)
        self.productsRemote = ProductsRemote(network: network)
        self.variationsRemote = ProductVariationsRemote(network: network)
        self.grdbManager = grdbManager
    }

    public func defaultStrategy(analytics: POSItemFetchAnalyticsTracking) -> PointOfSalePurchasableItemFetchStrategy {
        PointOfSaleDefaultPurchasableItemFetchStrategy(siteID: siteID,
                                                       productsRemote: productsRemote,
                                                       variationsRemote: variationsRemote,
                                                       analytics: analytics)
    }
    public func searchStrategy(searchTerm: String,
                               analytics: POSItemFetchAnalyticsTracking) -> PointOfSalePurchasableItemFetchStrategy {
        // Use local search if GRDB manager is available, otherwise fall back to remote search
        if let localStrategy = localSearchStrategy(searchTerm: searchTerm, analytics: analytics) {
            return localStrategy
        }
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

    /// Creates a local search strategy using the GRDB catalog
    /// - Parameters:
    ///   - searchTerm: The search term to query
    ///   - analytics: Analytics tracker
    ///   - pageSize: Number of items per page (default: 25)
    /// - Returns: A local search strategy if GRDB manager is available, otherwise nil
    public func localSearchStrategy(searchTerm: String,
                                    analytics: POSItemFetchAnalyticsTracking,
                                    pageSize: Int = 25) -> PointOfSalePurchasableItemFetchStrategy? {
        guard let grdbManager else {
            return nil
        }
        return PointOfSaleLocalSearchPurchasableItemFetchStrategy(siteID: siteID,
                                                                  searchTerm: searchTerm,
                                                                  grdbManager: grdbManager,
                                                                  variationsRemote: variationsRemote,
                                                                  analytics: analytics,
                                                                  pageSize: pageSize)
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
