import Foundation
import protocol Yosemite.POSItemProvider
import protocol Yosemite.POSItem

struct POSItemsService {

    private let itemProvider: POSItemProvider

    init(itemProvider: POSItemProvider) {
        self.itemProvider = itemProvider
    }

    @MainActor
    func fetchItems(pageNumber: Int) async throws -> [any POSItem] {
        var newItems = try await itemProvider.providePointOfSaleItems(pageNumber: pageNumber)
        if pageNumber == 1 {
            newItems.insert(POSDiscount(), at: 0)
        }

        return newItems
    }
}
