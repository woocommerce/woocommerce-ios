import Foundation
@testable import PointOfSale
import struct Yosemite.POSOrder
import struct Yosemite.POSOrderItem
import struct Yosemite.POSOrderCustomAmount

final class MockPOSOrderListController: POSSearchingOrderListControllerProtocol {
    var ordersViewState: POSOrderListState = .empty
    var selectedOrder: POSOrder?
    var isLoadingOrderRefunds = false
    var displayedLineItems: [POSOrderItem] = []
    var displayedCustomAmounts: [POSOrderCustomAmount] = []
    var refundActionAvailability: RefundActionAvailability = .available
    var refundSelectableItems: [POSRefundSelectableItem] = []
    var currentRefundRequiresCardPresentRefund = false
    var hasModifiedRefundSelection = false
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
        refundSelectableItems = []
        hasModifiedRefundSelection = false
    }

    func updateOrder(orderID: Int64) async throws {
        updateOrderCalled = true
        spyUpdateOrderID = orderID

        if shouldThrowError {
            throw TestError.updateOrderFailed
        }
    }

    func preloadRefundDetails() async {}

    func searchOrders(searchTerm: String) async {}

    func clearSearchOrders() {}

    var stubStartRefundFlowResult: StartRefundFlowResult = .hasItemsToRefund

    func startRefundFlow() async -> StartRefundFlowResult {
        guard let order = selectedOrder else { return .failed }
        refundSelectableItems = order.lineItems.map {
            POSRefundSelectableItem(from: $0, isSelected: true, index: 0)
        }
        hasModifiedRefundSelection = false
        return stubStartRefundFlowResult
    }

    func toggleRefundItemSelection(at index: Int) {
        guard refundSelectableItems.indices.contains(index) else { return }
        refundSelectableItems[index].isSelected.toggle()
        hasModifiedRefundSelection = true
    }

    func clearRefundSelection() {
        refundSelectableItems = []
        hasModifiedRefundSelection = false
    }

    func toggleAllRefundItemsSelection() {
        guard !refundSelectableItems.isEmpty else { return }
        let allSelected = refundSelectableItems.allSatisfy { $0.isSelected }
        let newSelectionState = !allSelected
        for index in refundSelectableItems.indices {
            refundSelectableItems[index].isSelected = newSelectionState
        }
        hasModifiedRefundSelection = true
    }

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
            customerEmail: nil,
            refundReason: nil,
            isFullRefund: selectedItems.count == refundSelectableItems.count
        )
    }

    func loadOrderRefunds() async {}

    // MARK: - Refund Processing

    var processRefundCalled = false
    var spyProcessRefundReason: String?
    private(set) var spyRecordedRefundApprover: POSStaff?
    var shouldThrowProcessRefundError = false

    func recordRefundApprover(_ approver: POSStaff?) {
        spyRecordedRefundApprover = approver
    }

    func processRefund(reason: String?) async throws {
        processRefundCalled = true
        spyProcessRefundReason = reason

        if shouldThrowProcessRefundError {
            throw TestError.updateOrderFailed
        }
    }
}
