import Foundation
import enum Yosemite.POSItemType
import protocol Yosemite.POSSearchHistoryProviding
import enum Yosemite.POSItem

final class POSProductSearchable: POSSearchable {
    private let itemListType: ItemListType
    private let itemsController: PointOfSaleSearchingItemsControllerProtocol
    private let searchHistoryProvider: POSSearchHistoryProviding

    init(itemListType: ItemListType,
         itemsController: PointOfSaleSearchingItemsControllerProtocol,
         searchHistoryProvider: POSSearchHistoryProviding) {
        self.itemListType = itemListType
        self.itemsController = itemsController
        self.searchHistoryProvider = searchHistoryProvider
    }

    var searchHistory: [String] {
        searchHistoryProvider.searchHistory(for: itemListType.itemType)
    }

    var searchFieldPlaceholder: String {
        itemListType.itemType.searchFieldLabel
    }

    func performSearch(term: String) async {
        await itemsController.searchItems(searchTerm: term, baseItem: .root)
    }

    func clearSearchResults() {
        itemsController.clearSearchItems(baseItem: .root)
    }
}
