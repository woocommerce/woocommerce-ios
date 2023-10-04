import Combine
import Foundation
import Networking

import XCTest

/// Mock for `ProductCategoriesRemote`.
///
final class MockProductCategoriesRemote {
    /// The results to return based on the given site ID in `createProductCategoriesResult`.
    private var createProductCategoriesResult: Result<[ProductCategory], Error>?

    /// Returns the value when `createProductCategories` is called.
    func whenCreatingProductCategories(thenReturn result: Result<[ProductCategory], Error>) {
        createProductCategoriesResult = result
    }
}

extension MockProductCategoriesRemote: ProductCategoriesRemoteProtocol {
    func loadAllProductCategories(for siteID: Int64, pageNumber: Int, pageSize: Int, completion: @escaping ([Networking.ProductCategory]?, Error?) -> Void) {
        // no-op
    }

    func loadProductCategory(with categoryID: Int64, siteID: Int64, completion: @escaping (Result<Networking.ProductCategory, Error>) -> Void) {
        // no-op
    }

    func createProductCategory(for siteID: Int64, name: String, parentID: Int64?, completion: @escaping (Result<Networking.ProductCategory, Error>) -> Void) {
        // no-op
    }

    func updateProductCategory(_ category: Networking.ProductCategory) async throws -> Networking.ProductCategory {
        .fake()
    }

    func deleteProductCategory(for siteID: Int64, categoryID: Int64) async throws {
        // no-op
    }

    func createProductCategories(for siteID: Int64,
                                 names: [String],
                                 parentID: Int64?,
                                 completion: @escaping (Result<[ProductCategory], Error>) -> Void) {
        guard let result = createProductCategoriesResult else {
            XCTFail("Could not find result for creating product categories.")
            return
        }
        completion(result)
    }
}
