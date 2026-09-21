import Foundation
@testable import PointOfSale
import struct Yosemite.POSOrder
import struct Yosemite.POSOrderItem
import struct Yosemite.POSOrderCustomAmount

final class MockPOSOrderListController: POSSearchingOrderListControllerProtocol, POSOrderSelectionHandling {
    var ordersViewState: POSOrderListState = .empty
    var selectedOrder: POSOrder?
    var isLoadingOrderRefunds = false
    var orderDetailsItemsState: POSOrderDetailsItemsState {
        if isLoadingOrderRefunds {
            return .loading(rowCount: displayedLineItems.count + displayedCustomAmounts.count)
        }
        return .loaded(
            lineItems: displayedLineItems,
            customAmounts: displayedCustomAmounts,
            refundedItems: selectedOrder?.refunds.flatMap(\.items) ?? []
        )
    }
    var displayedLineItems: [POSOrderItem] = []
    var displayedCustomAmounts: [POSOrderCustomAmount] = []
    var updateOrderCalled = false
    var spyUpdateOrderID: Int64?
    var shouldThrowError = false
    private(set) var loadOrderRefundsCalled = false

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

    func loadOrderRefunds() async {
        loadOrderRefundsCalled = true
    }
}
