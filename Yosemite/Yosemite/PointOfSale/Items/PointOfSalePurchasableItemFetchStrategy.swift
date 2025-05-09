import Foundation
import protocol Networking.ProductsRemoteProtocol
import protocol Networking.ProductVariationsRemoteProtocol

public protocol PointOfSalePurchasableItemFetchStrategy {
    func fetchProducts(pageNumber: Int) async throws -> PagedItems<POSProduct>
    func fetchVariations(parentProductID: Int64, pageNumber: Int) async throws -> PagedItems<ProductVariation>
}

extension PointOfSalePurchasableItemFetchStrategy {
    var productTypes: [ProductType] { [.simple, .variable] }
}

public struct PointOfSaleDefaultPurchasableItemFetchStrategy: PointOfSalePurchasableItemFetchStrategy {
    private let siteID: Int64

    private let productsRemote: ProductsRemoteProtocol
    private let variationsRemote: ProductVariationsRemoteProtocol

    init(siteID: Int64, productsRemote: ProductsRemoteProtocol, variationsRemote: ProductVariationsRemoteProtocol) {
        self.siteID = siteID
        self.productsRemote = productsRemote
        self.variationsRemote = variationsRemote
    }

    public func fetchProducts(pageNumber: Int) async throws -> PagedItems<POSProduct> {
        return try await productsRemote.loadProductsForPointOfSale(for: siteID,
                                                                   productTypes: productTypes,
                                                                   pageNumber: pageNumber)
    }

    public func fetchVariations(parentProductID: Int64, pageNumber: Int) async throws -> PagedItems<ProductVariation> {
        try await variationsRemote
            .loadVariationsForPointOfSale(for: siteID,
                                          parentProductID: parentProductID,
                                          pageNumber: pageNumber)
    }
}

public struct PointOfSaleSearchPurchasableItemFetchStrategy: PointOfSalePurchasableItemFetchStrategy {
    private let siteID: Int64

    let searchTerm: String

    private let productsRemote: ProductsRemoteProtocol
    private let variationsRemote: ProductVariationsRemoteProtocol


    init(siteID: Int64, searchTerm: String, productsRemote: ProductsRemoteProtocol, variationsRemote: ProductVariationsRemoteProtocol) {
        self.siteID = siteID
        self.searchTerm = searchTerm
        self.productsRemote = productsRemote
        self.variationsRemote = variationsRemote
    }

    public func fetchProducts(pageNumber: Int) async throws -> PagedItems<POSProduct> {
        return try await productsRemote.searchProductsForPointOfSale(for: siteID,
                                                                     query: searchTerm,
                                                                     productTypes: productTypes,
                                                                     pageNumber: pageNumber)
    }

    public func fetchVariations(parentProductID: Int64, pageNumber: Int) async throws -> PagedItems<ProductVariation> {
        try await variationsRemote
            .loadVariationsForPointOfSale(for: siteID,
                                          parentProductID: parentProductID,
                                          pageNumber: pageNumber)
    }
}

public struct PointOfSalePopularPurchasableItemFetchStrategy: PointOfSalePurchasableItemFetchStrategy {
    private let siteID: Int64
    private let productsRemote: ProductsRemoteProtocol
    private let variationsRemote: ProductVariationsRemoteProtocol
    private let pageSize: Int

    init(siteID: Int64,
         pageSize: Int,
         productsRemote: ProductsRemoteProtocol,
         variationsRemote: ProductVariationsRemoteProtocol) {
        self.siteID = siteID
        self.productsRemote = productsRemote
        self.variationsRemote = variationsRemote
        self.pageSize = pageSize
    }

    public func fetchProducts(pageNumber: Int) async throws -> PagedItems<POSProduct> {
        let receivedItems = try await productsRemote.loadPopularProductsForPointOfSale(for: siteID,
                                                                                       productTypes: productTypes,
                                                                                       pageNumber: pageNumber,
                                                                                       perPage: pageSize)
        let modifiedItems = PagedItems<POSProduct>(items: receivedItems.items,
                                                   hasMorePages: false)
        return modifiedItems
    }

    public func fetchVariations(parentProductID: Int64, pageNumber: Int) async throws -> PagedItems<ProductVariation> {
        try await variationsRemote
            .loadVariationsForPointOfSale(for: siteID,
                                          parentProductID: parentProductID,
                                          pageNumber: pageNumber)
    }
}
