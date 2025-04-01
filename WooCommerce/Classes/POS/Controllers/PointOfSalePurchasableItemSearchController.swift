import Foundation
import Observation
import protocol Yosemite.PointOfSaleItemSearchServiceProtocol

@available(iOS 17.0, *)
protocol PointOfSalePurchasableItemSearchControllerProtocol {
    var itemsViewState: ItemsViewState { get }
    /// Loads the first page of items for a given search term.
    func searchItems(searchTerm: String) async
    /// Loads the next page of items for the most recent search term.
    func loadNextItems() async
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

    func searchItems(searchTerm: String) async {
        itemProvider.updateSearchTerm(searchTerm)
        await itemsController.loadItems(base: .root)
    }

    func loadNextItems() async {
        await itemsController.loadNextItems(base: .root)
    }

}
