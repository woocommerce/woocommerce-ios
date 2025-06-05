import Foundation

@testable import Yosemite

final class MockPointOfSalePurchasableItemFetchStrategy: PointOfSalePurchasableItemFetchStrategy {
    var fetchProductsCalled = false
    var spyFetchProductsPageNumber: Int?
    var mockPagedProductsResult: Result<PagedItems<POSProduct>, Error>?
    var mockPagedVariationsResult: Result<PagedItems<ProductVariation>, Error>?

    func fetchProducts(pageNumber: Int) async throws -> PagedItems<POSProduct> {
        fetchProductsCalled = true
        spyFetchProductsPageNumber = pageNumber
        switch mockPagedProductsResult {
        case .success(let mockPagedProducts):
            return mockPagedProducts
        case .failure(let error):
            throw error
        case .none:
            return PagedItems<POSProduct>(items: [], hasMorePages: false, totalItems: nil)
        }
    }

    var fetchVariationsCalled = false
    var spyFetchVariationsParentProductID: Int64?
    var spyFetchVariationsPageNumber: Int?
    func fetchVariations(parentProductID: Int64, pageNumber: Int) async throws -> PagedItems<ProductVariation> {
        fetchVariationsCalled = true
        spyFetchVariationsParentProductID = parentProductID
        spyFetchVariationsPageNumber = pageNumber
        switch mockPagedVariationsResult {
        case .success(let mockPagedVariations):
            return mockPagedVariations
        case .failure(let error):
            throw error
        case .none:
            return PagedItems<ProductVariation>(items: [], hasMorePages: false, totalItems: nil)
        }
    }
}
