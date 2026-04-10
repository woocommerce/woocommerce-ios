import Foundation
import Combine
@testable import PointOfSale
import enum Yosemite.POSItem

final class MockPointOfSaleItemsController: PointOfSaleItemsControllerProtocol {
    var itemsViewState: ItemsViewState = .init(containerState: .content,
                                               itemsStack: .init(root: .empty, itemStates: [:]))

    func loadItems(base: ItemListBaseItem) async { }

    func refreshItems(base: ItemListBaseItem) async { }

    func loadNextItems(base: ItemListBaseItem) async { }
}
