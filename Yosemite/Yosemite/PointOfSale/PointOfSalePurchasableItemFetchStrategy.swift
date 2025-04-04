import Foundation
import class Networking.ProductsRemote
import class Networking.ProductVariationsRemote

public protocol PointOfSalePurchasableItemFetchStrategy {
    func fetchProducts(pageNumber: Int) async throws -> PagedItems<POSProduct>
    func fetchVariations(parentProductID: Int64, pageNumber: Int) async throws -> PagedItems<ProductVariation>
}

public struct PointOfSaleDefaultPurchasableItemFetchStrategy: PointOfSalePurchasableItemFetchStrategy {
    private let siteID: Int64

    private let productsRemote: ProductsRemote
    private let variationsRemote: ProductVariationsRemote

    init(siteID: Int64, productsRemote: ProductsRemote, variationsRemote: ProductVariationsRemote) {
        self.siteID = siteID
        self.productsRemote = productsRemote
        self.variationsRemote = variationsRemote
    }

    public func fetchProducts(pageNumber: Int) async throws -> PagedItems<POSProduct> {
        let productTypes: [ProductType] = [.simple, .variable]
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

    private let productsRemote: ProductsRemote
    private let variationsRemote: ProductVariationsRemote


    init(siteID: Int64, searchTerm: String, productsRemote: ProductsRemote, variationsRemote: ProductVariationsRemote) {
        self.siteID = siteID
        self.searchTerm = searchTerm
        self.productsRemote = productsRemote
        self.variationsRemote = variationsRemote
    }

    public func fetchProducts(pageNumber: Int) async throws -> PagedItems<POSProduct> {
        let productTypes: [ProductType] = [.simple, .variable]
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
