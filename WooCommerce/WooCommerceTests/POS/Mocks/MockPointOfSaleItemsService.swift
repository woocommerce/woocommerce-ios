import Foundation
import Combine
@testable import WooCommerce
import enum Yosemite.POSItem

final class MockPointOfSaleItemsController: PointOfSaleItemsControllerProtocol {
    var itemsViewStatePublisher: any Publisher<ItemsViewState, Never> = Empty()

    func loadInitialItems() async { }

    func loadNextItems() async { }

    func reload() async { }
}
