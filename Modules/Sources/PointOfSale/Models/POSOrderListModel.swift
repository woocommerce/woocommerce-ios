import Foundation
import Observation
import CocoaLumberjackSwift
import struct Yosemite.POSOrder

@MainActor
@Observable final class POSOrderListModel {
    let ordersController: POSSearchingOrderListControllerProtocol
    let receiptSender: POSReceiptSending
    let refundSubmissionModel: POSRefundSubmissionModel
    private let orderSelectionHandler: POSOrderSelectionHandling
    private let refundController: POSRefundControllerProtocol

    init(ordersController: POSSearchingOrderListControllerProtocol & POSOrderSelectionHandling,
         refundController: POSRefundControllerProtocol,
         receiptSender: POSReceiptSending,
         refundSubmissionModel: POSRefundSubmissionModel) {
        self.ordersController = ordersController
        self.orderSelectionHandler = ordersController
        self.refundController = refundController
        self.receiptSender = receiptSender
        self.refundSubmissionModel = refundSubmissionModel
    }

    func sendReceipt(order: POSOrder, email: String) async throws {
        try await receiptSender.sendReceipt(orderID: order.id, recipientEmail: email)
        try await ordersController.updateOrder(orderID: order.id)
    }

    func selectOrder(_ order: POSOrder?) {
        orderSelectionHandler.selectOrder(order)
        refundController.reset()
    }

    // MARK: - Refund Flow

    var refundActionAvailability: RefundActionAvailability {
        ordersController.selectedOrder?.refundActionAvailability ?? .unavailable
    }

    var refundSelectableItems: [POSRefundSelectableItem] {
        refundController.selectableItems
    }

    var hasLoadedRefundableItems: Bool {
        refundController.hasLoadedSelectableItems
    }

    var hasModifiedRefundSelection: Bool {
        refundController.hasModifiedSelection
    }

    var refundReviewPreparationState: POSRefundReviewPreparationState {
        refundController.reviewPreparationState
    }

    var requiresCardPresentRefund: Bool {
        refundController.requiresCardPresentRefund
    }

    func preloadRefund() async {
        guard let order = ordersController.selectedOrder else {
            return
        }
        await refundController.preloadRefund(for: order)
    }

    func startRefundFlow() async -> StartRefundFlowResult {
        guard let order = ordersController.selectedOrder else {
            return .failed
        }
        return await refundController.startRefundFlow(for: order)
    }

    func refreshRefundableItems() async -> StartRefundFlowResult {
        await refundController.refreshRefundableItems()
    }

    func toggleRefundItemSelection(at index: Int) {
        refundController.toggleItemSelection(at: index)
    }

    func toggleAllRefundItemsSelection() {
        refundController.toggleAllItemsSelection()
    }

    func clearRefundSelection() {
        refundController.clearSelection()
    }

    func prepareRefundReview() async -> POSRefundReviewPreparationResult {
        await refundController.prepareReview()
    }

    func processRefund(reason: String?) async throws {
        let result = try await refundController.processRefund(reason: reason)
        do {
            try await ordersController.updateOrder(orderID: result.refundedOrderID)
        } catch {
            DDLogError("⛔️ Failed to refresh order \(result.refundedOrderID) after refund: \(error)")
        }
        await ordersController.loadOrderRefunds()
    }
}
