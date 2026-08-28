import Foundation

@testable import Yosemite

final class MockPointOfSalePurchasableItemFetchStrategy: PointOfSalePurchasableItemFetchStrategy {
    var fetchItemsCalled = false
    var spyFetchItemsPageNumber: Int?
    var mockPagedProductsResult: Result<PagedItems<POSProduct>, Error>?
    var mockPagedItemsResult: Result<PagedItems<POSItem>, Error>?
    var mockPagedVariationsResult: Result<PagedItems<POSProductVariation>, Error>?

    func fetchItems(pageNumber: Int) async throws -> POSItemFetchResult {
        fetchItemsCalled = true
        spyFetchItemsPageNumber = pageNumber

        if let mockPagedItemsResult {
            switch mockPagedItemsResult {
            case .success(let mockPagedItems):
                return .items(mockPagedItems)
            case .failure(let error):
                throw error
            }
        }

        switch mockPagedProductsResult {
        case .success(let mockPagedProducts):
            return .products(mockPagedProducts)
        case .failure(let error):
            throw error
        case .none:
            return .products(PagedItems<POSProduct>(items: [], hasMorePages: false, totalItems: nil))
        }
    }

    var fetchVariationsCalled = false
    var spyFetchVariationsParentProductID: Int64?
    var spyFetchVariationsPageNumber: Int?
    func fetchVariations(parentProductID: Int64, pageNumber: Int) async throws -> PagedItems<POSProductVariation> {
        fetchVariationsCalled = true
        spyFetchVariationsParentProductID = parentProductID
        spyFetchVariationsPageNumber = pageNumber
        switch mockPagedVariationsResult {
        case .success(let mockPagedVariations):
            return mockPagedVariations
        case .failure(let error):
            throw error
        case .none:
            return PagedItems<POSProductVariation>(items: [], hasMorePages: false, totalItems: nil)
        }
    }
}
