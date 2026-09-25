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
        let orderBeforeRefund = ordersController.selectedOrder
        let result = try await refundController.processRefund(reason: reason)
        // Open the drawer so the cashier can hand the cash back, without holding up the refund flow.
        if result.isCashRefund, let cashDrawer {
            Task { await cashDrawer.openAutomatically(for: .cashRefund) }
        }
        do {
            try await ordersController.updateOrder(orderID: result.refundedOrderID)
            if result.isCashRefund, let cashSessionService {
                let updatedOrder = ordersController.selectedOrder?.id == result.refundedOrderID
                    ? ordersController.selectedOrder
                    : ordersController.ordersViewState.orders.first { $0.id == result.refundedOrderID }
                if let orderBeforeRefund, orderBeforeRefund.id == result.refundedOrderID, let updatedOrder {
                    let knownRefundIDs = Set(orderBeforeRefund.refunds.map(\.refundID))
                    let newRefunds = updatedOrder.refunds.filter { !knownRefundIDs.contains($0.refundID) }
                    if newRefunds.count == 1, let refundID = newRefunds.first?.refundID {
                        Task {
                            do {
                                _ = try await cashSessionService.recordCashRefund(orderID: result.refundedOrderID, refundID: refundID)
                            } catch {
                                DDLogError("💵 [CashSession] Failed to record cash refund \(refundID) for order \(result.refundedOrderID): \(error)")
                            }
                        }
                    } else {
                        DDLogError("💵 [CashSession] Cannot identify new refund for order \(result.refundedOrderID)")
                    }
                } else {
                    DDLogError("💵 [CashSession] Refunded order \(result.refundedOrderID) is unavailable for cash event")
                }
            }
        } catch {
            DDLogError("⛔️ Failed to refresh order \(result.refundedOrderID) after refund: \(error)")
        }
        await ordersController.loadOrderRefunds()
    }
}
