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
    /// Optional: nil when the cash drawer prototype is off (`.pointOfSaleCashDrawer`).
    private let cashDrawer: POSCashDrawerController?
    private let cashSessionService: (any POSCashSessionService)?

    init(ordersController: POSSearchingOrderListControllerProtocol & POSOrderSelectionHandling,
         refundController: POSRefundControllerProtocol,
         receiptSender: POSReceiptSending,
         refundSubmissionModel: POSRefundSubmissionModel,
         cashDrawer: POSCashDrawerController? = nil,
         cashSessionService: (any POSCashSessionService)? = nil) {
        self.ordersController = ordersController
        self.orderSelectionHandler = ordersController
        self.refundController = refundController
        self.receiptSender = receiptSender
        self.refundSubmissionModel = refundSubmissionModel
        self.cashDrawer = cashDrawer
        self.cashSessionService = cashSessionService
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
        let cashSessionID = refundController.isCashRefund ? try await cashSessionService?.captureCashSession() : nil
        let result = try await refundController.processRefund(reason: reason)
        // Open the drawer so the cashier can hand the cash back, without holding up the refund flow.
        if result.isCashRefund, let cashDrawer {
            Task { await cashDrawer.openAutomatically(for: .cashRefund) }
        }
        if result.isCashRefund, let cashSessionService, let cashSessionID {
            do {
                try cashSessionService.enqueueCashRefund(orderID: result.refundedOrderID, refundID: result.refundID, sessionID: cashSessionID)
            } catch {
                DDLogError("💵 [CashSession] Failed to persist cash refund \(result.refundID) for order \(result.refundedOrderID): \(error)")
            }
            Task { await cashSessionService.retryPendingCashMovements() }
        }
        do {
            try await ordersController.updateOrder(orderID: result.refundedOrderID)
        } catch {
            DDLogError("⛔️ Failed to refresh order \(result.refundedOrderID) after refund: \(error)")
        }
        await ordersController.loadOrderRefunds()
    }
}
