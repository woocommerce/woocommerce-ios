import Foundation
import enum Yosemite.POSItemType
import protocol Yosemite.POSSearchHistoryProviding

@available(iOS 17.0, *)

final class POSProductSearchable: POSSearchable {
    internal let itemListType: ItemListType
    private let itemsController: PointOfSaleSearchingItemsControllerProtocol
    private let searchHistoryProvider: POSSearchHistoryProviding

    init(itemListType: ItemListType,
         itemsController: PointOfSaleSearchingItemsControllerProtocol,
         searchHistoryProvider: POSSearchHistoryProviding) {
        switch itemListType {
        case .products:
            self.itemListType = .products(search: false)
        case .coupons:
            self.itemListType = .coupons(search: false)
        }
        self.itemsController = itemsController
        self.searchHistoryProvider = searchHistoryProvider
    }

    var searchHistory: [String] {
        searchHistoryProvider.searchHistory(for: itemListType.itemType)
    }

    func performSearch(term: String) async {
        await itemsController.searchItems(searchTerm: term, baseItem: .root)
    }
}
