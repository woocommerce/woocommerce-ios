import Foundation
import Combine
@testable import WooCommerce
import protocol Yosemite.POSDisplayableItem

final class MockPointOfSaleItemsController: PointOfSaleItemsControllerProtocol {
    var itemListStatePublisher: any Publisher<WooCommerce.ItemListState, Never> = Empty()

    var allItems: [POSDisplayableItem] = []

    func loadInitialItems() async { }

    func loadNextItems() async { }

    func reload() async { }
}
