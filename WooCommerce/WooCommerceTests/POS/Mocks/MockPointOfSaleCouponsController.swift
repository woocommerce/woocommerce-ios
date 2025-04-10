@testable import WooCommerce

@available(iOS 17.0, *)
final class MockPointOfSaleCouponsController: PointOfSaleCouponsControllerProtocol {
    func enableCoupons() async { }

    var itemsViewState: ItemsViewState = .init(containerState: .content,
                                               itemsStack: .init(root: .empty, itemStates: [:]))

    func loadItems(base: ItemListBaseItem) async { }

    func refreshItems(base: ItemListBaseItem) async { }

    func loadNextItems(base: ItemListBaseItem) async { }
}
