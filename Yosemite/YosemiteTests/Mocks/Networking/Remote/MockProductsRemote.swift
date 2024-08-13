
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

    /// The results to return based on the given site ID in `loadAllProducts`
    private var loadAllProductsResultsBySiteID = [Int64: Result<[Product], Error>]()

    /// The results to return based on the given site ID in `loadNumberOfProducts`.
    private var loadNumberOfProductsResultsBySiteID = [Int64: Result<Int64, Error>]()

    private var searchProductsResultsByQuery = [String: Result<[Product], Error>]()

    private var searchProductsBySKUResultsBySKU = [String: Result<[Product], Error>]()

    private var fetchedStockResult: Result<[ProductStock], Error>?
    private var fetchedProductReports: Result<[ProductReport], Error>?
    private var fetchedVariationReports: Result<[ProductReport], Error>?

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

    /// Set the value passed to the `completion` block if `loadAllProducts()` is called.
    ///
    func whenLoadingAllProducts(siteID: Int64, thenReturn result: Result<[Product], Error>) {
        loadAllProductsResultsBySiteID[siteID] = result
    }

    /// Set the value passed to the `completion` block if `loadNumberOfProducts()` is called.
    ///
    func whenLoadingNumberOfProducts(siteID: Int64, thenReturn result: Result<Int64, Error>) {
        loadNumberOfProductsResultsBySiteID[siteID] = result
    }

    /// Set the value passed to the `completion` block if `searchProducts()` is called.
    ///
    func whenSearchingProducts(query: String, thenReturn result: Result<[Product], Error>) {
        searchProductsResultsByQuery[query] = result
    }

    /// Set the value passed to the `completion` block if `searchProductsBySKU()` is called.
    ///
    func whenSearchingProductsBySKU(sku: String, thenReturn result: Result<[Product], Error>) {
        searchProductsBySKUResultsBySKU[sku] = result
    }

    func whenFetchingStock(thenReturn result: Result<[ProductStock], Error>) {
        fetchedStockResult = result
    }

    func whenFetchingProductReports(thenReturn result: Result<[ProductReport], Error>) {
        fetchedProductReports = result
    }

    func whenFetchingVariationReports(thenReturn result: Result<[ProductReport], Error>) {
        fetchedVariationReports = result
    }
}

// MARK: - ProductsEndpointsProviding

extension MockProductsRemote: ProductsRemoteProtocol {
    func addProduct(product: Product, completion: @escaping (Result<Product, Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            if let result = self.addProductResultsBySiteID[product.siteID] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for site ID \(product.siteID)")
            }
        }
    }

    func deleteProduct(for siteID: Int64, productID: Int64, completion: @escaping (Result<Product, Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            if let result = self.deleteProductResultsBySiteID[siteID] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for site ID \(siteID)")
            }
        }
    }

    func loadProduct(for siteID: Int64,
                     productID: Int64,
                     completion: @escaping (Result<Product, Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            self.invocationCountOfLoadProduct += 1

            let key = ResultKey(siteID: siteID, productIDs: [productID])
            if let result = self.productLoadingResults[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }

    func loadProducts(for siteID: Int64, by productIDs: [Int64], pageNumber: Int, pageSize: Int, completion: @escaping (Result<[Product], Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            let key = ResultKey(siteID: siteID, productIDs: productIDs)
            if let result = self.productsLoadingResults[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
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
                         excludedProductIDs: [Int64],
                         completion: @escaping (Result<[Product], Error>) -> Void) {
        if let result = loadAllProductsResultsBySiteID[siteID] {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(siteID)")
        }
    }

    func searchProducts(for siteID: Int64,
                        keyword: String,
                        pageNumber: Int,
                        pageSize: Int,
                        stockStatus: ProductStockStatus?,
                        productStatus: ProductStatus?,
                        productType: ProductType?,
                        productCategory: ProductCategory?,
                        excludedProductIDs: [Int64],
                        completion: @escaping (Result<[Product], Error>) -> Void) {
        searchProductTriggered = true
        searchProductWithStockStatus = stockStatus
        searchProductWithProductType = productType
        searchProductWithProductStatus = productStatus
        searchProductWithProductCategory = productCategory
        if let result = searchProductsResultsByQuery[keyword] {
            completion(result)
        }
    }

    func searchProductsBySKU(for siteID: Int64,
                             keyword: String,
                             pageNumber: Int,
                             pageSize: Int,
                             completion: @escaping (Result<[Product], Error>) -> Void) {
        if let result = searchProductsBySKUResultsBySKU[keyword] {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find result for SKU \(keyword)")
        }
    }

    func searchSku(for siteID: Int64, sku: String, completion: @escaping (Result<String, Error>) -> Void) {
        // no-op
    }

    func updateProduct(product: Product, completion: @escaping (Result<Product, Error>) -> Void) {
        // no-op
    }

    func updateProductImages(siteID: Int64, productID: Int64, images: [ProductImage], completion: @escaping (Result<Product, Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let key = ResultKey(siteID: siteID, productIDs: [productID])
            if let result = self.updateProductImagesResultsBySiteID[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }

    func updateProducts(siteID: Int64, products: [Product], completion: @escaping (Result<[Product], Error>) -> Void) {
        // no-op
    }

    func loadProductIDs(for siteID: Int64,
                        pageNumber: Int,
                        pageSize: Int,
                        productStatus: ProductStatus?,
                        completion: @escaping (Result<[Int64], Error>) -> Void) {
        // no-op
    }

    func loadNumberOfProducts(siteID: Int64) async throws -> Int64 {
        guard let result = loadNumberOfProductsResultsBySiteID[siteID] else {
            throw NetworkError.notFound()
        }
        do {
            let numberOfProducts = try result.get()
            return numberOfProducts
        } catch {
            throw error
        }
    }

    func loadStock(for siteID: Int64,
                   with stockType: String,
                   pageNumber: Int,
                   pageSize: Int,
                   order: ProductsRemote.Order) async throws -> [ProductStock] {
        guard let result = fetchedStockResult else {
            throw NetworkError.notFound()
        }
        switch result {
        case let .success(stock):
            return stock
        case let .failure(error):
            throw error
        }
    }

    func loadProductReports(for siteID: Int64,
                            productIDs: [Int64],
                            timeZone: TimeZone,
                            earliestDateToInclude: Date,
                            latestDateToInclude: Date,
                            pageSize: Int,
                            pageNumber: Int,
                            orderBy: ProductsRemote.OrderKey,
                            order: ProductsRemote.Order) async throws -> [ProductReport] {
        guard let result = fetchedProductReports else {
            throw NetworkError.notFound()
        }
        switch result {
        case let .success(reports):
            return reports
        case let .failure(error):
            throw error
        }
    }

    func loadVariationReports(for siteID: Int64,
                                     productIDs: [Int64],
                                     variationIDs: [Int64],
                                     timeZone: TimeZone,
                                     earliestDateToInclude: Date,
                                     latestDateToInclude: Date,
                                     pageSize: Int,
                                     pageNumber: Int,
                                     orderBy: ProductsRemote.OrderKey,
                              order: ProductsRemote.Order) async throws -> [ProductReport] {
        guard let result = fetchedVariationReports else {
            throw NetworkError.notFound()
        }
        switch result {
        case let .success(reports):
            return reports
        case let .failure(error):
            throw error
        }
    }
}
