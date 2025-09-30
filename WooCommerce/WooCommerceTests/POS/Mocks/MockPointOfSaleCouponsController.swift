@testable import WooCommerce

final class MockPointOfSaleCouponsController: PointOfSaleCouponsControllerProtocol {
    var loadItemsCalled = false
    var loadItemsBase: ItemListBaseItem?

    var itemsViewState: ItemsViewState = .init(containerState: .content,
                                               itemsStack: .init(root: .empty, itemStates: [:]))

    func loadItems(base: ItemListBaseItem) async {
        loadItemsCalled = true
        loadItemsBase = base
    }

    func refreshItems(base: ItemListBaseItem) async { }
    func loadNextItems(base: ItemListBaseItem) async { }
    func enableCoupons() async { }
    func searchItems(searchTerm: String, baseItem: WooCommerce.ItemListBaseItem) async { }
    func clearSearchItems(baseItem: WooCommerce.ItemListBaseItem) { }
}
