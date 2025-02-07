import Foundation
import Combine
@testable import WooCommerce
import enum Yosemite.POSItem

@available(iOS 17.0, *)
final class MockPointOfSaleItemsController: PointOfSaleItemsControllerProtocol {
    var itemsViewState: ItemsViewState = .init(containerState: .empty,
                                               itemsStack: .init(root: .loaded([], hasMoreItems: false),
                                                                 itemStates: [:]))

    func loadItems(base: ItemListBaseItem) async { }

    func loadNextItems(base: ItemListBaseItem) async { }
}
