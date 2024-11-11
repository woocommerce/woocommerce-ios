import Foundation
@testable import WooCommerce
import protocol Yosemite.POSItem

final class MockPointOfSaleAggregateModel: PointOfSaleAggregateModelProtocol {
    var allItems: [POSItem] {
        switch itemListState {
        case .empty,
                .initialLoading,
                .error:
            return []
        case .loading(let items),
            .loaded(let items):
            return items
        }
    }
    
    var itemListState: ItemListState

    init(itemListState: ItemListState = .initialLoading) {
        self.itemListState = itemListState
    }

    func loadInitialItems() async { }

    func loadItems(pageNumber: Int) async { }

    func reload() async { }
}
