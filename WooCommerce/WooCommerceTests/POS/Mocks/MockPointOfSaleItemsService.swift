import Foundation
import Combine
@testable import WooCommerce
import protocol Yosemite.POSItem

final class MockPointOfSaleItemsService: PointOfSaleItemsServiceProtocol {
    var itemListStatePublisher: any Publisher<WooCommerce.ItemListState, Never> = Empty()

    var allItems: [any POSItem] = []

    func loadInitialItems() async { }

    func loadNextItems() async { }

    func reload() async { }
}
