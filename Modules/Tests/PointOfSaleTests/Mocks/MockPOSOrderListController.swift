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
        case loadOrderFailed
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

    var stubStartRefundFlowResult: StartRefundFlowResult = .hasItemsToRefund

    func startRefundFlow() async -> StartRefundFlowResult {
        guard let order = selectedOrder else { return .failed }
        refundSelectableItems = order.lineItems.map {
            POSRefundSelectableItem(from: $0, isSelected: true, index: 0)
        }
        return stubStartRefundFlowResult
    }

    func toggleRefundItemSelection(at index: Int) {
        guard refundSelectableItems.indices.contains(index) else { return }
        refundSelectableItems[index].isSelected.toggle()
    }

    func clearRefundSelection() {
        refundSelectableItems = []
    }

    func toggleAllRefundItemsSelection() {}

    // MARK: - Refund Review Data

    var stubPOSRefundReviewData: POSRefundReviewData?

    func preparePOSRefundReviewData() -> POSRefundReviewData? {
        if let stubData = stubPOSRefundReviewData {
            return stubData
        }

        let selectedItems = refundSelectableItems.filter { $0.isSelected }
        guard !selectedItems.isEmpty else { return nil }

        return POSRefundReviewData(
            itemsCount: selectedItems.count,
            formattedItemsSubtotal: "$0.00",
            formattedTax: "$0.00",
            formattedRefundTotal: "$0.00",
            paymentMethodDescription: "Via payment card",
            refundReason: nil
        )
    }

    // MARK: - Refund Processing

    var processRefundCalled = false
    var spyProcessRefundReason: String?
    var shouldThrowProcessRefundError = false

    func processRefund(reason: String?) async throws {
        processRefundCalled = true
        spyProcessRefundReason = reason

        if shouldThrowProcessRefundError {
            throw TestError.updateOrderFailed
        }
    }
}
