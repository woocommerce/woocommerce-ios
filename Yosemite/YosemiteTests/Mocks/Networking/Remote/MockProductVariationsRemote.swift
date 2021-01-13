
import Foundation
import Networking

import XCTest

/// Mock for `MockProductVariationsRemote`.
///
final class MockProductVariationsRemote {
    private struct ResultKey: Hashable {
        let siteID: Int64
        let productID: Int64
        let productVariationIDs: [Int64]
    }

    /// The results to return based on the given arguments in `createProductVariation`
    private var productVariationCreateResults = [ResultKey: Result<ProductVariation, Error>]()

    /// The results to return based on the given arguments in `updateProductVariation`
    private var productVariationUpdateResults = [ResultKey: Result<ProductVariation, Error>]()

    /// The results to return based on the given arguments in `loadProductVariation`
    private var productVariationLoadResults = [ResultKey: Result<ProductVariation, Error>]()

    /// Set the value passed to the `completion` block if `createProductVariation()` is called.
    ///
    func whenCreatingProductVariation(siteID: Int64,
                                      productID: Int64,
                                      productVariationID: Int64,
                                      thenReturn result: Result<ProductVariation, Error>) {
        let key = ResultKey(siteID: siteID, productID: productID, productVariationIDs: [productVariationID])
        productVariationCreateResults[key] = result
    }


    /// Set the value passed to the `completion` block if `updateProductVariation()` is called.
    ///
    func whenUpdatingProductVariation(siteID: Int64, productID: Int64, productVariationID: Int64, thenReturn result: Result<ProductVariation, Error>) {
        let key = ResultKey(siteID: siteID, productID: productID, productVariationIDs: [productVariationID])
        productVariationUpdateResults[key] = result
    }

    /// Set the value passed to the `completion` block if `loadProductVariation()` is called.
    ///
    func whenLoadingProductVariation(siteID: Int64, productID: Int64, productVariationID: Int64, thenReturn result: Result<ProductVariation, Error>) {
        let key = ResultKey(siteID: siteID, productID: productID, productVariationIDs: [productVariationID])
        productVariationLoadResults[key] = result
    }
}

// MARK: - ProductVariationsRemoteProtocol conformance

extension MockProductVariationsRemote: ProductVariationsRemoteProtocol {
    func loadAllProductVariations(for siteID: Int64,
                                  productID: Int64,
                                  context: String?,
                                  pageNumber: Int,
                                  pageSize: Int,
                                  completion: @escaping ([ProductVariation]?, Error?) -> Void) {
        // no-op
    }

    func loadProductVariation(for siteID: Int64, productID: Int64, variationID: Int64, completion: @escaping (Result<ProductVariation, Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            let key = ResultKey(siteID: siteID,
                                productID: productID,
                                productVariationIDs: [variationID])
            if let result = self.productVariationLoadResults[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }

    func createProductVariation(for siteID: Int64,
                                 productID: Int64,
                                 newVariation: CreateProductVariation,
                                 completion: @escaping (Result<ProductVariation, Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            let key = ResultKey(siteID: siteID,
                                productID: productID,
                                productVariationIDs: [1275] )
            if let result = self.productVariationCreateResults[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }

    func updateProductVariation(productVariation: ProductVariation, completion: @escaping (Result<ProductVariation, Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            let key = ResultKey(siteID: productVariation.siteID,
                                productID: productVariation.productID,
                                productVariationIDs: [productVariation.productVariationID])
            if let result = self.productVariationUpdateResults[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }
}
