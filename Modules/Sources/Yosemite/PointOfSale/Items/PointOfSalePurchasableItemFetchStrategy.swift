import Foundation
import protocol Networking.ProductsRemoteProtocol
import protocol Networking.ProductVariationsRemoteProtocol

public protocol PointOfSalePurchasableItemFetchStrategy {
    func fetchProducts(pageNumber: Int) async throws -> PagedItems<POSProduct>
    func fetchVariations(parentProductID: Int64, pageNumber: Int) async throws -> PagedItems<POSProductVariation>

    /// Fetches mixed POSItem results (products and variations together).
    /// Override this in strategies that need to return both products and variations (e.g., FTS search).
    /// Default implementation returns nil, indicating the service should use fetchProducts instead.
    func fetchMixedItems(pageNumber: Int) async throws -> PagedItems<POSItem>?

    /// The debouncing strategy to use for search input.
    /// Default is `.immediate` (no debouncing) for non-search strategies.
    var debounceStrategy: SearchDebounceStrategy { get }
}

public extension PointOfSalePurchasableItemFetchStrategy {
    /// Default implementation returns `.immediate` for strategies that don't need debouncing
    var debounceStrategy: SearchDebounceStrategy {
        .immediate
    }

    /// Default implementation returns nil, indicating the service should use fetchProducts instead.
    func fetchMixedItems(pageNumber: Int) async throws -> PagedItems<POSItem>? {
        nil
    }
}

public struct PointOfSaleDefaultPurchasableItemFetchStrategy: PointOfSalePurchasableItemFetchStrategy {
    private let siteID: Int64

    private let productsRemote: ProductsRemoteProtocol
    private let variationsRemote: ProductVariationsRemoteProtocol
    private let analytics: POSItemFetchAnalyticsTracking
    private let posProductsOnly: Bool

    static var defaultProductTypes: [ProductType] { [.simple, .variable] }

    init(siteID: Int64,
         productsRemote: ProductsRemoteProtocol,
         variationsRemote: ProductVariationsRemoteProtocol,
         analytics: POSItemFetchAnalyticsTracking,
         posProductsOnly: Bool = false) {
        self.siteID = siteID
        self.productsRemote = productsRemote
        self.variationsRemote = variationsRemote
        self.analytics = analytics
        self.posProductsOnly = posProductsOnly
    }

    public func fetchProducts(pageNumber: Int) async throws -> PagedItems<POSProduct> {
        let pagedProducts = try await productsRemote.loadProductsForPointOfSale(
            for: siteID,
            productTypes: PointOfSaleDefaultPurchasableItemFetchStrategy.defaultProductTypes,
            pageNumber: pageNumber,
            posProductsOnly: posProductsOnly
        )

        if pageNumber == 1 {
            analytics.trackItemsFetchComplete(totalItems: pagedProducts.totalItems ?? 0)
        }

        return pagedProducts
    }

    public func fetchVariations(parentProductID: Int64, pageNumber: Int) async throws -> PagedItems<POSProductVariation> {
        try await variationsRemote
            .loadVariationsForPointOfSale(for: siteID,
                                          parentProductID: parentProductID,
                                          pageNumber: pageNumber,
                                          posProductsOnly: posProductsOnly)
    }
}

public struct PointOfSaleSearchPurchasableItemFetchStrategy: PointOfSalePurchasableItemFetchStrategy {
    private let siteID: Int64

    let searchTerm: String

    private let productsRemote: ProductsRemoteProtocol
    private let variationsRemote: ProductVariationsRemoteProtocol
    private let analytics: POSItemFetchAnalyticsTracking
    private let posProductsOnly: Bool

    init(siteID: Int64,
         searchTerm: String,
         productsRemote: ProductsRemoteProtocol,
         variationsRemote: ProductVariationsRemoteProtocol,
         analytics: POSItemFetchAnalyticsTracking,
         posProductsOnly: Bool = false) {
        self.siteID = siteID
        self.searchTerm = searchTerm
        self.productsRemote = productsRemote
        self.variationsRemote = variationsRemote
        self.analytics = analytics
        self.posProductsOnly = posProductsOnly
    }

    // periphery:ignore - Protocol requirement, used via protocol
    public var debounceStrategy: SearchDebounceStrategy {
        // Use smart debouncing for remote search: don't debounce first keystroke to show loading immediately,
        // then debounce subsequent keystrokes while search is ongoing.
        // No loading delay threshold - show loading immediately for responsive feel.
        .smart()
    }

    public func fetchProducts(pageNumber: Int) async throws -> PagedItems<POSProduct> {
        let startTime = Date()
        let pagedProducts = try await productsRemote.searchProductsForPointOfSale(
            for: siteID,
            query: searchTerm,
            productTypes: PointOfSaleDefaultPurchasableItemFetchStrategy.defaultProductTypes,
            pageNumber: pageNumber,
            posProductsOnly: posProductsOnly
        )
        if pageNumber == 1 {
            let milliseconds = Int(Date().timeIntervalSince(startTime) * Double(MSEC_PER_SEC))
            analytics.trackSearchRemoteResultsFetchComplete(millisecondsSinceRequestSent: milliseconds,
                                                            totalItems: pagedProducts.totalItems ?? 0)
        }
        return pagedProducts
    }

    public func fetchVariations(parentProductID: Int64, pageNumber: Int) async throws -> PagedItems<POSProductVariation> {
        try await variationsRemote
            .loadVariationsForPointOfSale(for: siteID,
                                          parentProductID: parentProductID,
                                          pageNumber: pageNumber,
                                          posProductsOnly: posProductsOnly)
    }
}

public struct PointOfSalePopularPurchasableItemFetchStrategy: PointOfSalePurchasableItemFetchStrategy {
    private let siteID: Int64
    private let productsRemote: ProductsRemoteProtocol
    private let variationsRemote: ProductVariationsRemoteProtocol
    private let pageSize: Int
    private let posProductsOnly: Bool

    init(siteID: Int64,
         pageSize: Int,
         productsRemote: ProductsRemoteProtocol,
         variationsRemote: ProductVariationsRemoteProtocol,
         posProductsOnly: Bool = false) {
        self.siteID = siteID
        self.productsRemote = productsRemote
        self.variationsRemote = variationsRemote
        self.pageSize = pageSize
        self.posProductsOnly = posProductsOnly
    }

    public func fetchProducts(pageNumber: Int) async throws -> PagedItems<POSProduct> {
        let receivedItems = try await productsRemote.loadPopularProductsForPointOfSale(
            for: siteID,
            productTypes: PointOfSaleDefaultPurchasableItemFetchStrategy.defaultProductTypes,
            pageNumber: pageNumber,
            perPage: pageSize,
            posProductsOnly: posProductsOnly
        )
        let modifiedItems = PagedItems<POSProduct>(items: receivedItems.items,
                                                   hasMorePages: false,
                                                   totalItems: receivedItems.totalItems)
        return modifiedItems
    }

    public func fetchVariations(parentProductID: Int64, pageNumber: Int) async throws -> PagedItems<POSProductVariation> {
        try await variationsRemote
            .loadVariationsForPointOfSale(for: siteID,
                                          parentProductID: parentProductID,
                                          pageNumber: pageNumber,
                                          posProductsOnly: posProductsOnly)
    }
}
