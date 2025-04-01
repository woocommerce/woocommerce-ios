import Foundation
import Observation
import protocol Yosemite.PointOfSaleItemSearchServiceProtocol

@available(iOS 17.0, *)
protocol PointOfSalePurchasableItemSearchControllerProtocol {
    var itemsViewState: ItemsViewState { get }
    /// Loads the first page of items for a given search term.
    func searchItems(searchTerm: String, base: ItemListBaseItem) async
    /// Loads the next page of items for the most recent search term.
    func loadNextItems(base: ItemListBaseItem) async

    func loadItems(base: ItemListBaseItem) async
    /// Refreshes the items for a given base item – will result in showing only the first page.
    func refreshItems(base: ItemListBaseItem) async
    /// Loads the next page of items for a given base item.
}


@available(iOS 17.0, *)
@Observable final class PointOfSalePurchasableItemSearchController: PointOfSalePurchasableItemSearchControllerProtocol {
    var itemsViewState: ItemsViewState {
        itemsController.itemsViewState
    }

    private let itemProvider: PointOfSaleItemSearchServiceProtocol
    private let itemsController: PointOfSaleItemsController

    init(itemProvider: PointOfSaleItemSearchServiceProtocol) {
        self.itemProvider = itemProvider
        self.itemsController = PointOfSaleItemsController(itemProvider: itemProvider)
    }

    func searchItems(searchTerm: String, base: ItemListBaseItem = .root) async {
        itemProvider.updateSearchTerm(searchTerm)
        await itemsController.loadItems(base: base)
    }

    func loadNextItems(base: ItemListBaseItem) async {
        await itemsController.loadNextItems(base: base)
    }

    func loadItems(base: ItemListBaseItem) async {
        await itemsController.loadItems(base: base)
    }

    func refreshItems(base: ItemListBaseItem) async {
        await itemsController.refreshItems(base: base)
    }

}
