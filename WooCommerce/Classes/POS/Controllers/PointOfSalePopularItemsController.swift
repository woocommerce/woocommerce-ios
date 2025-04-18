import Foundation
import Observation
import enum Yosemite.POSItem
import enum Yosemite.POSItemType
import class Yosemite.PointOfSaleItemService
import protocol Yosemite.PointOfSaleItemServiceProtocol
import protocol Yosemite.PointOfSalePurchasableItemFetchStrategy

@available(iOS 17.0, *)
protocol PointOfSalePopularItemsControllerProtocol {
    var itemsByType: [POSItemType: [POSItem]] { get }

    var isLoading: Bool { get }

    func loadPopularItems(for type: POSItemType) async
}

@available(iOS 17.0, *)
@Observable final class PointOfSalePopularItemsController: PointOfSalePopularItemsControllerProtocol {
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
                let productNames = pagedItems.items.compactMap { item -> String? in
                    switch item {
                    case .simpleProduct(let product): return product.name
                    case .variableParentProduct(let product): return product.name
                    default: return nil
                    }
                }
                DDLogInfo("📊 Loaded popular items of type \(type): \(productNames.joined(separator: ", "))")
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
