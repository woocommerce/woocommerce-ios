import Foundation

public protocol PointOfSaleItemSearchServiceProtocol: PointOfSaleItemServiceProtocol {
    func updateSearchTerm(_ searchTerm: String)
}

public final class PointOfSaleItemSearchService: PointOfSaleItemSearchServiceProtocol {

    private var itemService: PointOfSaleItemService

    public init(itemService: PointOfSaleItemService) {
        self.itemService = itemService
    }

    private var searchTerm: String = ""

    public func updateSearchTerm(_ searchTerm: String) {
        self.searchTerm = searchTerm
    }

    public func providePointOfSaleItems(pageNumber: Int) async throws -> PagedItems<POSItem> {
        try await self.itemService.provideSearchedPointOfSaleItems(query: searchTerm, pageNumber: pageNumber)
    }

    public func providePointOfSaleVariationItems(for parentProduct: POSVariableParentProduct, pageNumber: Int) async throws -> PagedItems<POSItem> {
        try await self.itemService.providePointOfSaleVariationItems(
            for: parentProduct,
            pageNumber: pageNumber)
    }
}
