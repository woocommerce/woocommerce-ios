
import Foundation
import Networking

import XCTest

/// Mock for `ProductsRemote`.
///
final class MockProductsRemote {
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
                         orderBy: ProductsRemote.OrderKey,
                         order: ProductsRemote.Order,
                         excludedProductIDs: [Int64],
                         completion: @escaping (Result<[Product], Error>) -> Void) {
        // no-op
    }

    func searchProducts(for siteID: Int64,
                        keyword: String,
                        pageNumber: Int,
                        pageSize: Int,
                        excludedProductIDs: [Int64],
                        completion: @escaping ([Product]?, Error?) -> Void) {
        // no-op
    }

    func searchSku(for siteID: Int64, sku: String, completion: @escaping (String?, Error?) -> Void) {
        // no-op
    }

    func updateProduct(product: Product, completion: @escaping (Result<Product, Error>) -> Void) {
        // no-op
    }
}
