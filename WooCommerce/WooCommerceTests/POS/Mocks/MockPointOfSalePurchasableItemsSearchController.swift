import Foundation
import Combine
@testable import WooCommerce
import enum Yosemite.POSItem

final class MockPointOfSalePurchasableItemsSearchController: PointOfSaleSearchingItemsControllerProtocol {
    var itemsViewState: ItemsViewState = .init(containerState: .content,
                                               itemsStack: .init(root: .empty, itemStates: [:]))

    func searchItems(searchTerm: String, baseItem: ItemListBaseItem) async {}

    func loadItems(base: ItemListBaseItem) async { }

    func refreshItems(base: ItemListBaseItem) async { }

    func loadNextItems(base: ItemListBaseItem) async { }

    func clearSearchItems(baseItem: WooCommerce.ItemListBaseItem) { }
}
