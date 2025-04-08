@testable import WooCommerce

@available(iOS 17.0, *)
final class MockPointOfSaleCouponsController: PointOfSaleCouponsControllerProtocol {
    func enableCoupons() async { }
    
    var itemsViewState: ItemsViewState = .init(containerState: .empty,
                                               itemsStack: .init(root: .loaded([], hasMoreItems: false),
                                                                 itemStates: [:]))

    func loadItems(base: ItemListBaseItem) async { }

    func refreshItems(base: ItemListBaseItem) async { }

    func loadNextItems(base: ItemListBaseItem) async { }
}
