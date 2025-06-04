import Foundation

@testable import Yosemite

final class MockPointOfSalePurchasableItemFetchStrategy: PointOfSalePurchasableItemFetchStrategy {
    var fetchProductsCalled = false
    var spyFetchProductsPageNumber: Int?
    var mockPagedProducts: PagedItems<POSProduct>?
    var mockPagedVariations: PagedItems<ProductVariation>?
    var mockError: Error?

    func fetchProducts(pageNumber: Int) async throws -> PagedItems<POSProduct> {
        fetchProductsCalled = true
        spyFetchProductsPageNumber = pageNumber
        if let error = mockError {
            throw error
        }
        return mockPagedProducts ?? .init(items: [], hasMorePages: false, totalItems: nil)
    }

    var fetchVariationsCalled = false
    var spyFetchVariationsParentProductID: Int64?
    var spyFetchVariationsPageNumber: Int?
    func fetchVariations(parentProductID: Int64, pageNumber: Int) async throws -> PagedItems<ProductVariation> {
        fetchVariationsCalled = true
        spyFetchVariationsParentProductID = parentProductID
        spyFetchVariationsPageNumber = pageNumber
        if let error = mockError {
            throw error
        }
        return mockPagedVariations ?? .init(items: [], hasMorePages: false, totalItems: nil)
    }
}
