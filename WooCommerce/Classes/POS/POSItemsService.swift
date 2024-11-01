import Foundation
import protocol Yosemite.POSItemProvider
import protocol Yosemite.POSItem

struct POSItemsService {

    private let itemProvider: POSItemProvider

    init(itemProvider: POSItemProvider) {
        self.itemProvider = itemProvider
    }

    @MainActor
    func fetchItems(pageNumber: Int,
                    currentItems: [any POSDisplayableItem]) async throws -> [any POSDisplayableItem] {
        var newItems = try await itemProvider.providePointOfSaleItems(pageNumber: pageNumber)
        if pageNumber == 1 {
            newItems.insert(POSDiscount(), at: 0)
        }

        let uniqueNewItems = newItems
            .filter { newItem in
                !currentItems.contains(where: { $0.id == newItem.itemID })
            }
            .compactMap(createPOSDisplayableItem(for:))

        let allItems = currentItems + uniqueNewItems
        return allItems
    }
}
