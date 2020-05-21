
import Foundation
import Networking

import XCTest

/// Mock for `ProductsRemote`.
///
final class MockProductsRemote: ProductsEndpointsProviding {
    private struct ResultKey: Hashable {
        let siteID: Int64
        let productID: Int64
    }

    /// The results to return based on the given arguments in `loadProduct`
    private var productLoadingResults = [ResultKey: Result<Product, Error>]()

    /// Set the value passed to the `completion` block if `loadProduct()` is called.
    ///
    func whenLoadingProduct(siteID: Int64, productID: Int64, thenReturn result: Result<Product, Error>) {
        let key = ResultKey(siteID: siteID, productID: productID)
        productLoadingResults[key] = result
    }

    func loadProduct(for siteID: Int64,
                     productID: Int64,
                     completion: @escaping (Result<Product, Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            let key = ResultKey(siteID: siteID, productID: productID)
            if let result = self.productLoadingResults[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }
}
