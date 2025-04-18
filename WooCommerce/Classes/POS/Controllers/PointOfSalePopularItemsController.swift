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
    private var fetchStrategy: PointOfSalePurchasableItemFetchStrategy

    // Maps item types to their items
    private(set) var itemsByType: [POSItemType: [POSItem]] = [:]
    private(set) var isLoading = false

    init(itemProvider: PointOfSaleItemServiceProtocol,
         fetchStrategy: PointOfSalePurchasableItemFetchStrategy) {
        self.itemProvider = itemProvider
        self.fetchStrategy = fetchStrategy
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
            // When we support more types here, we'll probably need a fetch strategy factory
            itemsByType[type] = []
        }

        isLoading = false
    }
}
