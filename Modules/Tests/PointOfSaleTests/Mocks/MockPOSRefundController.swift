import Foundation
@testable import PointOfSale
import struct Yosemite.POSOrder

final class MockPOSRefundController: POSRefundControllerProtocol {
    var selectableItems: [POSRefundSelectableItem] = []
    var hasLoadedSelectableItems: Bool { !selectableItems.isEmpty }
    var hasModifiedSelection = false
    var reviewPreparationState: POSRefundReviewPreparationState = .idle
    var requiresCardPresentRefund = false
    var stubRefundActionAvailability: RefundActionAvailability = .available

    private(set) var preloadedOrderID: Int64?
    private(set) var startRefundFlowOrderID: Int64?
    private(set) var refreshRefundableItemsCallCount = 0
    private(set) var clearSelectionCalled = false
    private(set) var resetCalled = false
    private(set) var processRefundCalled = false
    private(set) var spyProcessRefundReason: String?

    var stubStartRefundFlowResult: StartRefundFlowResult = .hasItemsToRefund
    var stubReviewPreparationResult: POSRefundReviewPreparationResult = .preparationError
    var stubProcessRefundOrderID: Int64 = 0
    var processRefundErrorToThrow: Error?

    enum TestError: Error {
        case processRefundFailed
    }

    func refundActionAvailability(for order: POSOrder?) -> RefundActionAvailability {
        stubRefundActionAvailability
    }

    func preloadRefund(for order: POSOrder) async {
        preloadedOrderID = order.id
    }

    func startRefundFlow(for order: POSOrder) async -> StartRefundFlowResult {
        startRefundFlowOrderID = order.id
        return stubStartRefundFlowResult
    }

    func refreshRefundableItems() async -> StartRefundFlowResult {
        refreshRefundableItemsCallCount += 1
        if case .hasItemsToRefund = stubStartRefundFlowResult {
            for index in selectableItems.indices {
                selectableItems[index].isSelected = false
            }
            hasModifiedSelection = false
        }
        return stubStartRefundFlowResult
    }

    func toggleItemSelection(at index: Int) {
        guard selectableItems.indices.contains(index) else { return }
        selectableItems[index].isSelected.toggle()
        hasModifiedSelection = true
    }

    func toggleAllItemsSelection() {
        guard !selectableItems.isEmpty else { return }
        let newSelectionState = !selectableItems.allSatisfy { $0.isSelected }
        for index in selectableItems.indices {
            selectableItems[index].isSelected = newSelectionState
        }
        hasModifiedSelection = true
    }

    func clearSelection() {
        clearSelectionCalled = true
        selectableItems = []
        hasModifiedSelection = false
    }

    func reset() {
        resetCalled = true
        clearSelection()
    }

    func prepareReview() async -> POSRefundReviewPreparationResult {
        stubReviewPreparationResult
    }

    func processRefund(reason: String?) async throws -> Int64 {
        processRefundCalled = true
        spyProcessRefundReason = reason

        if let processRefundErrorToThrow {
            throw processRefundErrorToThrow
        }

        return stubProcessRefundOrderID
    }
}
