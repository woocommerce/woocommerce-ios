
import Foundation
import Networking

import XCTest

/// Mock for `ProductsRemote`.
///
final class MockProductsRemote {
    private(set) var searchProductTriggered: Bool = false
    private(set) var searchProductWithStockStatus: ProductStockStatus?
    private(set) var searchProductWithProductStatus: ProductStatus?
    private(set) var searchProductWithProductType: ProductType?
    private(set) var searchProductWithProductCategory: ProductCategory?

    private struct ResultKey: Hashable {
        let siteID: Int64
        let productIDs: [Int64]
    }

    /// The results to return based on the given arguments in `loadProduct`
    private var productLoadingResults = [ResultKey: Result<Product, Error>]()

    /// The results to return based on the given arguments in `loadProducts`
    private var productsLoadingResults = [ResultKey: Result<[Product], Error>]()

    /// The results to return based on the given site ID in `addProduct`
    private var addProductResultsBySiteID = [Int64: Result<Product, Error>]()

    /// The results to return based on the given site ID in `deleteProduct`
    private var deleteProductResultsBySiteID = [Int64: Result<Product, Error>]()

    /// The results to return based on the given site ID in `updateProductImages`
    private var updateProductImagesResultsBySiteID = [ResultKey: Result<Product, Error>]()

    /// The number of times that `loadProduct()` was invoked.
    private(set) var invocationCountOfLoadProduct: Int = 0

    /// Set the value passed to the `completion` block if `addProduct()` is called.
    ///
    func whenAddingProduct(siteID: Int64, thenReturn result: Result<Product, Error>) {
        addProductResultsBySiteID[siteID] = result
    }

    /// Set the value passed to the `completion` block if `deleteProduct()` is called.
    ///
    func whenDeletingProduct(siteID: Int64, thenReturn result: Result<Product, Error>) {
        deleteProductResultsBySiteID[siteID] = result
    }

    /// Set the value passed to the `completion` block if `loadProduct()` is called.
    ///
    func whenLoadingProduct(siteID: Int64, productID: Int64, thenReturn result: Result<Product, Error>) {
        let key = ResultKey(siteID: siteID, productIDs: [productID])
        productLoadingResults[key] = result
    }

    /// Set the value passed to the `completion` block if `loadProducts()` is called.
    ///
    func whenLoadingProducts(siteID: Int64, productIDs: [Int64], thenReturn result: Result<[Product], Error>) {
        let key = ResultKey(siteID: siteID, productIDs: productIDs)
        productsLoadingResults[key] = result
    }

    /// Set the value passed to the `completion` block if `updateProductImages()` is called.
    ///
    func whenUpdatingProductImages(siteID: Int64, productID: Int64, thenReturn result: Result<Product, Error>) {
        let key = ResultKey(siteID: siteID, productIDs: [productID])
        updateProductImagesResultsBySiteID[key] = result
    }
}

// MARK: - ProductsEndpointsProviding

extension MockProductsRemote: ProductsRemoteProtocol {
    func addProduct(product: Product) async throws -> Product {
        if let result = self.addProductResultsBySiteID[product.siteID] {
            switch result {
            case .success(let product):
                return product
            case .failure(let error):
                throw error
            }
        }
        fatalError("MockProductsRemote: addProduct not returning a Product or throwing an Error")
    }

    func deleteProduct(for siteID: Int64, productID: Int64) async throws -> Product {
        if let result = self.deleteProductResultsBySiteID[siteID] {
            switch result {
            case .success(let product):
                return product
            case .failure(let error):
                throw error
            }
        }
        fatalError("MockProductsRemote: deleteProduct not returning a Product or throwing an Error")
    }

    func loadProduct(for siteID: Int64, productID: Int64) async throws -> Product {
        self.invocationCountOfLoadProduct += 1
        let key = ResultKey(siteID: siteID, productIDs: [productID])

        if let result = self.productLoadingResults[key] {
            switch result {
            case .success(let product):
                return product
            case .failure(let error):
                throw error
            }
        }
        fatalError("MockProductsRemote: loadProduct not returning a Product or throwing an Error")
    }

    func loadProducts(for siteID: Int64, by productIDs: [Int64], pageNumber: Int, pageSize: Int) async throws -> [Product] {
        let key = ResultKey(siteID: siteID, productIDs: productIDs)

        if let result = self.productsLoadingResults[key] {
            switch result {
            case .success(let products):
                return products
            case .failure(let error):
                throw error
            }
        }
        fatalError("MockProductsRemote: loadProducts not returning [Product] or throwing an Error")
    }

    func loadAllProducts(for siteID: Int64,
                         context: String?,
                         pageNumber: Int,
                         pageSize: Int,
                         stockStatus: ProductStockStatus?,
                         productStatus: ProductStatus?,
                         productType: ProductType?,
                         productCategory: ProductCategory?,
                         orderBy: ProductsRemote.OrderKey,
                         order: ProductsRemote.Order,
                         excludedProductIDs: [Int64])  async throws -> [Product] {
        // no-op
        return [Product.fake()]
    }

    func searchProducts(for siteID: Int64,
                        keyword: String,
                        pageNumber: Int,
                        pageSize: Int,
                        stockStatus: ProductStockStatus?,
                        productStatus: ProductStatus?,
                        productType: ProductType?,
                        productCategory: ProductCategory?,
                        excludedProductIDs: [Int64]) async throws -> [Product] {
        searchProductTriggered = true
        searchProductWithStockStatus = stockStatus
        searchProductWithProductType = productType
        searchProductWithProductStatus = productStatus
        searchProductWithProductCategory = productCategory
        // Check:
        return [Product.fake()]
    }

    func searchProductsBySKU(for siteID: Int64,
                             keyword: String,
                             pageNumber: Int,
                             pageSize: Int) async throws -> [Product] {
        // no-op
        return [Product.fake()]
    }

    func searchSku(for siteID: Int64, sku: String) async throws -> String {
        // no-op
        return ""
    }

    func updateProduct(product: Product) async throws -> Product {
        // no-op
        return Product.fake()
    }

    func updateProductImages(siteID: Int64, productID: Int64, images: [ProductImage]) async throws -> Product {
        let key = ResultKey(siteID: siteID, productIDs: [productID])
        if let result = self.updateProductImagesResultsBySiteID[key] {
            switch result {
            case .success(let product):
                return product
            case .failure(let error):
                throw error
            }
        }
        fatalError("MockProductsRemote: updateProductImages not returning a Product or throwing an Error")
    }

    func loadProductIDs(for siteID: Int64, pageNumber: Int, pageSize: Int) async throws -> [Int64] {
        // no-op
        return []
    }

    func createTemplateProduct(for siteID: Int64, template: ProductsRemote.TemplateType) async throws -> Int64 {
        // no-op
        return 0
    }
}
