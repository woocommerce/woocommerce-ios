import Foundation
import Observation
import enum Yosemite.OrderRefundEligibilityFailure
import enum Yosemite.RefundAPIError
import struct Yosemite.POSOrder

@MainActor
protocol POSRefundControllerProtocol {
    var selectableItems: [POSRefundSelectableItem] { get }
    var hasLoadedSelectableItems: Bool { get }
    var hasModifiedSelection: Bool { get }
    var reviewPreparationState: POSRefundReviewPreparationState { get }
    var requiresCardPresentRefund: Bool { get }
    func preloadRefund(for order: POSOrder) async
    func startRefundFlow(for order: POSOrder) async -> StartRefundFlowResult
    func refreshRefundableItems() async -> StartRefundFlowResult
    func toggleItemSelection(at index: Int)
    func toggleAllItemsSelection()
    func clearSelection()
    func reset()
    func prepareReview() async -> POSRefundReviewPreparationResult
    func processRefund(reason: String?) async throws -> POSRefundSubmissionResult
}

@MainActor
@Observable final class POSRefundController: POSRefundControllerProtocol {
    private(set) var selectableItems: [POSRefundSelectableItem] = []
    private(set) var hasModifiedSelection = false
    private(set) var reviewPreparationState: POSRefundReviewPreparationState = .idle

    private var order: POSOrder?
    private var preparation: POSRefundPreparation?

    private let refundSubmissionProcessor: POSRefundSubmissionProcessing
    private var reviewPreparationTask: Task<POSRefundReviewPreparationResult, Never>?
    private var isProcessingRefund = false

    init(refundSubmissionProcessor: POSRefundSubmissionProcessing) {
        self.refundSubmissionProcessor = refundSubmissionProcessor
    }

    var requiresCardPresentRefund: Bool {
        preparation?.requiresCardPresentRefund ?? false
    }

    // MARK: - Refund Item Selection

    func preloadRefund(for order: POSOrder) async {
        guard order.refundActionAvailability == .available else {
            return
        }
        await refundSubmissionProcessor.preloadRefund(for: order)
    }

    func startRefundFlow(for order: POSOrder) async -> StartRefundFlowResult {
        self.order = order

        let preparation: POSRefundPreparation
        do {
            preparation = try await refundSubmissionProcessor.prepareRefund(for: order)
            self.preparation = preparation
        } catch let eligibilityFailure as OrderRefundEligibilityFailure {
            self.preparation = nil
            return .ineligible(eligibilityFailure)
        } catch {
            self.preparation = nil
            return .failed
        }

        selectableItems = preparation.selectableItems
        hasModifiedSelection = false
        resetReviewPreparation()

        return selectableItems.isEmpty ? .nothingToRefund : .hasItemsToRefund
    }

    var hasLoadedSelectableItems: Bool {
        !selectableItems.isEmpty
    }

    func refreshRefundableItems() async -> StartRefundFlowResult {
        guard let order else { return .failed }

        let result = await startRefundFlow(for: order)
        guard case .hasItemsToRefund = result else {
            return result
        }

        for index in selectableItems.indices {
            selectableItems[index].isSelected = false
        }
        return result
    }

    func toggleItemSelection(at index: Int) {
        guard selectableItems.indices.contains(index) else { return }
        selectableItems[index].isSelected.toggle()
        hasModifiedSelection = true
        resetReviewPreparation()
    }

    func toggleAllItemsSelection() {
        guard !selectableItems.isEmpty else { return }
        let allSelected = selectableItems.allSatisfy { $0.isSelected }
        let newSelectionState = !allSelected
        for index in selectableItems.indices {
            selectableItems[index].isSelected = newSelectionState
        }
        hasModifiedSelection = true
        resetReviewPreparation()
    }

    func clearSelection() {
        selectableItems = []
        hasModifiedSelection = false
        resetReviewPreparation()
    }

    func reset() {
        order = nil
        preparation = nil
        clearSelection()
    }

    // MARK: - Refund Review Data Preparation

    func prepareReview() async -> POSRefundReviewPreparationResult {
        reviewPreparationTask?.cancel()

        guard let order, let preparation else {
            reviewPreparationState = .idle
            return .preparationError
        }

        let selectedItems = selectableItems.filter { $0.isSelected }
        guard !selectedItems.isEmpty else {
            reviewPreparationState = .idle
            return .preparationError
        }

        let selectionSnapshot = selectableItems
        reviewPreparationState = .loading
        let preparationTask = Task { @MainActor [weak self] () -> POSRefundReviewPreparationResult in
            guard let self else { return .superseded }
            let state: POSRefundReviewPreparationState
            let result: POSRefundReviewPreparationResult
            do {
                let reviewData = try await refundSubmissionProcessor.prepareReviewData(
                    for: order,
                    preparation: preparation,
                    selectedItems: selectedItems,
                    reason: nil
                )
                state = .idle
                result = .ready(reviewData)
            } catch is CancellationError {
                return .superseded
            } catch POSRefundSubmissionError.refundPreviewFailed {
                state = .previewError()
                result = .previewError
            } catch RefundAPIError.orderNotRefundable {
                state = .idle
                result = .nothingToRefund
            } catch let rejection as RefundAPIError {
                state = .previewError(message: rejection.localizedDescription, recovery: rejection.recovery)
                result = .previewError
            } catch {
                state = .idle
                result = .preparationError
            }
            // Applied once for every outcome: a result computed against a selection the cashier has
            // since changed must not be published, and a new catch must not be able to skip the check.
            guard !Task.isCancelled, selectableItems == selectionSnapshot else { return .superseded }
            reviewPreparationState = state
            return result
        }
        reviewPreparationTask = preparationTask
        return await preparationTask.value
    }

    private func resetReviewPreparation() {
        reviewPreparationTask?.cancel()
        reviewPreparationTask = nil
        reviewPreparationState = .idle
    }

    // MARK: - Refund Processing

    func processRefund(reason: String?) async throws -> POSRefundSubmissionResult {
        guard !isProcessingRefund else {
            throw POSRefundProcessingError.refundAlreadyInProgress
        }

        isProcessingRefund = true
        defer {
            isProcessingRefund = false
        }

        guard let order else {
            throw POSRefundProcessingError.missingSelectedOrder
        }

        guard let preparation else {
            throw POSRefundProcessingError.missingRefundPreparation
        }

        let selectedItems = selectableItems.filter { $0.isSelected }
        guard !selectedItems.isEmpty else {
            throw POSRefundProcessingError.emptySelection
        }

        try await refundSubmissionProcessor.submitRefund(
            for: order,
            preparation: preparation,
            selectedItems: selectedItems,
            reason: reason
        )

        clearSelection()
        return POSRefundSubmissionResult(refundedOrderID: order.id)
    }
}
