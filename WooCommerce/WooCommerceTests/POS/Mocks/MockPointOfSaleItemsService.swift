import Foundation
import Combine
@testable import WooCommerce
import enum Yosemite.POSItem

final class MockPointOfSaleItemsController: PointOfSaleItemsControllerProtocol {
    var itemListStatePublisher: any Publisher<WooCommerce.ItemListState, Never> = Empty()

    var allItems: [POSItem] = []

    func loadInitialItems() async { }

    func loadNextItems() async { }

    func reload() async { }
}
