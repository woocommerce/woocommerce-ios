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

    func loadNextItems() async { }

    func reload() async { }

    var cart: [CartItem] = []

    func addToCart(_ item: any Yosemite.POSItem) { }

    func remove(cartItem: WooCommerce.CartItem) { }

    var removeAllItemsFromCartCalled = false
    func removeAllItemsFromCart() {
        removeAllItemsFromCartCalled = true
    }
}
