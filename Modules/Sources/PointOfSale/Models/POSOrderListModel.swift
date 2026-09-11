import Foundation
import Observation
import CocoaLumberjackSwift
import struct Yosemite.POSOrder

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

    @MainActor
    func selectOrder(_ order: POSOrder?) {
        orderSelectionHandler.selectOrder(order)
        refundController.reset()
    }

    // MARK: - Refund Flow

    @MainActor
    var refundActionAvailability: RefundActionAvailability {
        ordersController.selectedOrder?.refundActionAvailability ?? .unavailable
    }

    @MainActor
    var refundSelectableItems: [POSRefundSelectableItem] {
        refundController.selectableItems
    }

    @MainActor
    var hasLoadedRefundableItems: Bool {
        refundController.hasLoadedSelectableItems
    }

    @MainActor
    var hasModifiedRefundSelection: Bool {
        refundController.hasModifiedSelection
    }

    @MainActor
    var refundReviewPreparationState: POSRefundReviewPreparationState {
        refundController.reviewPreparationState
    }

    @MainActor
    var requiresCardPresentRefund: Bool {
        refundController.requiresCardPresentRefund
    }

    @MainActor
    func preloadRefund() async {
        guard let order = ordersController.selectedOrder else {
            return
        }
        await refundController.preloadRefund(for: order)
    }

    @MainActor
    func startRefundFlow() async -> StartRefundFlowResult {
        guard let order = ordersController.selectedOrder else {
            return .failed
        }
        return await refundController.startRefundFlow(for: order)
    }

    @MainActor
    func refreshRefundableItems() async -> StartRefundFlowResult {
        await refundController.refreshRefundableItems()
    }

    @MainActor
    func toggleRefundItemSelection(at index: Int) {
        refundController.toggleItemSelection(at: index)
    }

    @MainActor
    func toggleAllRefundItemsSelection() {
        refundController.toggleAllItemsSelection()
    }

    @MainActor
    func clearRefundSelection() {
        refundController.clearSelection()
    }

    @MainActor
    func prepareRefundReview() async -> POSRefundReviewPreparationResult {
        await refundController.prepareReview()
    }

    @MainActor
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
