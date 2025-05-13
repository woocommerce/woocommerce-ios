import Foundation

@testable import Yosemite

final class MockPointOfSalePurchasableItemFetchStrategy: PointOfSalePurchasableItemFetchStrategy {
    var fetchProductsCalled = false
    var spyFetchProductsPageNumber: Int?
    func fetchProducts(pageNumber: Int) async throws -> PagedItems<POSProduct> {
        fetchProductsCalled = true
        spyFetchProductsPageNumber = pageNumber
        return .init(items: [], hasMorePages: false, totalItems: nil)
    }

    var fetchVariationsCalled = false
    var spyFetchVariationsParentProductID: Int64?
    var spyFetchVariationsPageNumber: Int?
    func fetchVariations(parentProductID: Int64, pageNumber: Int) async throws -> PagedItems<ProductVariation> {
        fetchVariationsCalled = true
        spyFetchVariationsParentProductID = parentProductID
        spyFetchVariationsPageNumber = pageNumber
        return .init(items: [], hasMorePages: false, totalItems: nil)
    }
}
