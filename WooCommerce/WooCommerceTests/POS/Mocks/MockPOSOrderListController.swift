import Foundation
@testable import WooCommerce
import struct Yosemite.POSOrder

final class MockPOSOrderListController: POSOrderListControllerProtocol {
    var ordersViewState: POSOrderListState = .empty
    var selectedOrder: POSOrder?
    var updateOrderCalled = false
    var spyUpdateOrderID: Int64?
    var shouldThrowError = false

    enum TestError: Error {
        case updateOrderFailed
    }

    func loadOrders() async {}

    func refreshOrders() async {}

    func loadNextOrders() async {}

    func selectOrder(_ order: POSOrder?) {
        selectedOrder = order
    }

    func updateOrder(orderID: Int64) async throws {
        updateOrderCalled = true
        spyUpdateOrderID = orderID

        if shouldThrowError {
            throw TestError.updateOrderFailed
        }
    }

    func searchOrders(searchTerm: String) async {}

    func clearSearchOrders() {}
}
