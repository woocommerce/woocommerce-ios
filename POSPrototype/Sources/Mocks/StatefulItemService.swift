import Foundation
import Yosemite
import struct Networking.PagedItems

final class StatefulItemService: PointOfSaleItemServiceProtocol {
    private let configuration: MockConfiguration

    init(configuration: MockConfiguration) {
        self.configuration = configuration
    }

    func providePointOfSaleItems(pageNumber: Int,
                                 fetchStrategy: PointOfSalePurchasableItemFetchStrategy) async throws -> PagedItems<POSItem> {
        try await Task.sleep(nanoseconds: UInt64(configuration.productLoadDelay * 1_000_000_000))
        return PagedItems(items: configuration.products, hasMorePages: false, totalItems: configuration.products.count)
    }

    func providePointOfSaleVariationItems(for parentProduct: POSVariableParentProduct,
                                          pageNumber: Int,
                                          fetchStrategy: PointOfSalePurchasableItemFetchStrategy) async throws -> PagedItems<POSItem> {
        PagedItems(items: [], hasMorePages: false, totalItems: 0)
    }
}
