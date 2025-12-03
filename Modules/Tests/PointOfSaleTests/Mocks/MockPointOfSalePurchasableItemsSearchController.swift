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

    func searchItems(searchTerm: String, baseItem: ItemListBaseItem) async {}

    func loadItems(base: ItemListBaseItem) async { }

    func refreshItems(base: ItemListBaseItem) async { }

    func loadNextItems(base: ItemListBaseItem) async { }

    func clearSearchItems(baseItem: ItemListBaseItem) { }
}
