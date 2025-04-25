import Foundation
import enum Yosemite.POSItemType
import protocol Yosemite.POSSearchHistoryProviding

@available(iOS 17.0, *)
final class POSProductSearchable: POSSearchable {
    private let itemsController: PointOfSaleSearchingItemsControllerProtocol
    private let searchHistoryProvider: POSSearchHistoryProviding

    init(itemsController: PointOfSaleSearchingItemsControllerProtocol,
         searchHistoryProvider: POSSearchHistoryProviding) {
        self.itemsController = itemsController
        self.searchHistoryProvider = searchHistoryProvider
    }

    var itemType: POSItemType {
        .product
    }

    var searchHistory: [String] {
        searchHistoryProvider.searchHistory(for: itemType)
    }

    func performSearch(term: String) async {
        await itemsController.searchItems(searchTerm: term, baseItem: .root)
    }
}
