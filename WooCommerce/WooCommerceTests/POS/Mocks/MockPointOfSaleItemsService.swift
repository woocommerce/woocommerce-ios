import Foundation
import Combine
@testable import WooCommerce
import protocol Yosemite.POSDisplayableItem

final class MockPointOfSaleItemsController: PointOfSaleItemsControllerProtocol {
    var itemListStatePublisher: any Publisher<WooCommerce.ItemsViewState, Never> = Empty()

    var allItems: [POSDisplayableItem] = []

    func loadInitialItems() async { }

    func loadNextItems() async { }

    func reload() async { }
}
