import Foundation
@testable import PointOfSale
import struct Yosemite.POSOrder

final class MockPOSOrderListController: POSSearchingOrderListControllerProtocol {
    var ordersViewState: POSOrderListState = .empty
    var selectedOrder: POSOrder?
    var refundActionAvailability: RefundActionAvailability = .available
    var refundSelectableItems: [POSRefundSelectableItem] = []
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

    func startRefundFlow() {
        guard let order = selectedOrder else { return }
        refundSelectableItems = order.lineItems.map {
            POSRefundSelectableItem(from: $0, isSelected: true)
        }
    }

    func toggleRefundItemSelection(at index: Int) {
        guard refundSelectableItems.indices.contains(index) else { return }
        refundSelectableItems[index].isSelected.toggle()
    }

    func clearRefundSelection() {
        refundSelectableItems = []
    }

    func toggleAllRefundItemsSelection() {}
}
