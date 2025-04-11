@testable import WooCommerce

@available(iOS 17.0, *)
final class MockPointOfSaleCouponsController: PointOfSaleCouponsControllerProtocol {
    var enableCouponsResult: Bool = false
    var loadItemsCalled = false
    var loadItemsBase: ItemListBaseItem?

    func enableCoupons() async -> Bool {
        return enableCouponsResult
    }

    var itemsViewState: ItemsViewState = .init(containerState: .content,
                                               itemsStack: .init(root: .empty, itemStates: [:]))

    func loadItems(base: ItemListBaseItem) async {
        loadItemsCalled = true
        loadItemsBase = base
    }

    func refreshItems(base: ItemListBaseItem) async { }
    func loadNextItems(base: ItemListBaseItem) async { }
    func searchItems(query: String) async { }
}
