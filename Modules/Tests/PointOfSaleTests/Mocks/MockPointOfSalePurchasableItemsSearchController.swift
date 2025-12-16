import Foundation
import Combine
@testable import PointOfSale
import enum Yosemite.POSItem
import enum Yosemite.SearchDebounceStrategy

final class MockPointOfSalePurchasableItemsSearchController: PointOfSaleSearchingItemsControllerProtocol {
    var itemsViewState: ItemsViewState = .init(containerState: .content,
                                               itemsStack: .init(root: .empty, itemStates: [:]))

    var currentDebounceStrategy: SearchDebounceStrategy = .immediate
    var searchDebounceStrategy: SearchDebounceStrategy = .smart()

    var searchItemsCalled = false
    var lastSearchTerm: String?
    var lastSearchBaseItem: ItemListBaseItem?

    var clearSearchItemsCalled = false
    var lastClearBaseItem: ItemListBaseItem?

    func searchItems(searchTerm: String, baseItem: ItemListBaseItem) async {
        searchItemsCalled = true
        lastSearchTerm = searchTerm
        lastSearchBaseItem = baseItem
    }

    func loadItems(base: ItemListBaseItem) async { }

    func refreshItems(base: ItemListBaseItem) async { }

    func loadNextItems(base: ItemListBaseItem) async { }

    func clearSearchItems(baseItem: ItemListBaseItem) {
        clearSearchItemsCalled = true
        lastClearBaseItem = baseItem
    }
}
