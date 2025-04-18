import Foundation
import Observation
import enum Yosemite.POSItem
import enum Yosemite.POSItemType
import class Yosemite.PointOfSaleItemService
import protocol Yosemite.PointOfSaleItemServiceProtocol
import class Yosemite.PointOfSaleItemFetchStrategyFactory
import protocol Yosemite.PointOfSalePurchasableItemFetchStrategy

@available(iOS 17.0, *)
@Observable final class PointOfSalePopularItemsController {
    private let itemProvider: PointOfSaleItemServiceProtocol
    private let itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory
    private var fetchStrategy: PointOfSalePurchasableItemFetchStrategy

    // Maps item types to their items
    private(set) var itemsByType: [POSItemType: [POSItem]] = [:]
    private(set) var isLoading = false

    init(itemProvider: PointOfSaleItemServiceProtocol,
         itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory) {
        self.itemProvider = itemProvider
        self.itemFetchStrategyFactory = itemFetchStrategyFactory
        self.fetchStrategy = itemFetchStrategyFactory.popularStrategy()
    }

    @MainActor
    func loadPopularItems(for type: POSItemType) async {
        isLoading = true

        switch type {
        case .product:
            do {
                let pagedItems = try await itemProvider.providePointOfSaleItems(pageNumber: 1,
                                                                                fetchStrategy: fetchStrategy)
                itemsByType[type] = pagedItems.items
            } catch {
                itemsByType[type] = []
            }
        case .coupon, .variation:
            itemsByType[type] = []
        }

        isLoading = false
    }
}
