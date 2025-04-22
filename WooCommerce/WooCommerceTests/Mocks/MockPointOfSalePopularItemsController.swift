import Foundation
@testable import WooCommerce
import Yosemite

final class MockPointOfSalePopularItemsController: PointOfSalePopularItemsControllerProtocol {
    var itemsByType: [POSItemType: [POSItem]] = [:]

    var isLoading: Bool = false

    func loadPopularItems(for type: POSItemType) async {}
}
