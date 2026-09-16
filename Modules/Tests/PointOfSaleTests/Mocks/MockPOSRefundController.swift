import Foundation
@testable import PointOfSale
import struct Yosemite.POSOrder

@MainActor
final class MockPOSRefundController: POSRefundControllerProtocol {
    var selectableItems: [POSRefundSelectableItem] = []
    var hasLoadedSelectableItems: Bool { !selectableItems.isEmpty }
    var hasModifiedSelection = false
    var reviewPreparationState: POSRefundReviewPreparationState = .idle
    var requiresCardPresentRefund = false

    private(set) var preloadedOrderID: Int64?
    private(set) var startRefundFlowOrderID: Int64?
    private(set) var resetCalled = false
    private(set) var processRefundCalled = false
    private(set) var spyProcessRefundReason: String?

    var stubStartRefundFlowResult: StartRefundFlowResult = .hasItemsToRefund
    var stubRefundedOrderID: Int64 = 123
    var processRefundErrorToThrow: Error?

    enum TestError: Error {
        case processRefundFailed
    }

    func preloadRefund(for order: POSOrder) async {
        preloadedOrderID = order.id
    }

    func startRefundFlow(for order: POSOrder) async -> StartRefundFlowResult {
        startRefundFlowOrderID = order.id
        return stubStartRefundFlowResult
    }

    func refreshRefundableItems() async -> StartRefundFlowResult {
        stubStartRefundFlowResult
    }

    func toggleItemSelection(at index: Int) {}

    func toggleAllItemsSelection() {}

    func clearSelection() {
        selectableItems = []
        hasModifiedSelection = false
    }

    func reset() {
        resetCalled = true
        clearSelection()
    }

    func prepareReview() async -> POSRefundReviewPreparationResult {
        .preparationError
    }

    func processRefund(reason: String?) async throws -> POSRefundSubmissionResult {
        processRefundCalled = true
        spyProcessRefundReason = reason

        if let processRefundErrorToThrow {
            throw processRefundErrorToThrow
        }

        return POSRefundSubmissionResult(refundedOrderID: stubRefundedOrderID)
    }
}
