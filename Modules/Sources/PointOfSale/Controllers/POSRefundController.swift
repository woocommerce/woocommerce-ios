import Foundation
import Observation
import enum Yosemite.RefundAPIError
import enum Yosemite.OrderRefundEligibilityFailure
import struct Yosemite.POSOrder

enum StartRefundFlowResult: Equatable {
    case hasItemsToRefund
    case nothingToRefund
    case ineligible(OrderRefundEligibilityFailure)
    case failed
}

/// Observable UI state for the selection sheet while review preparation runs (button spinner and
/// inline preview error). The preparation's outcome is returned by `prepareReview()` as a
/// `POSRefundReviewPreparationResult` instead of being published here.
enum POSRefundReviewPreparationState: Equatable {
    case idle
    case loading
    /// `message` carries the server's rejection copy when the preview failed with an actionable
    /// code (for example the order changed since the screen was loaded); `nil` shows the generic
    /// preview error copy. `recovery` is what the cashier is offered next to it.
    case previewError(message: String? = nil, recovery: POSRefundRecovery = .retry)
}

/// Outcome of `prepareReview()`, returned directly to the caller.
enum POSRefundReviewPreparationResult: Equatable {
    case ready(POSRefundReviewData)
    case previewError
    case preparationError
    /// The store rejected the preview because the order has nothing refundable left, so the flow
    /// ends on the terminal screen rather than back on the selection.
    case nothingToRefund
    /// A newer preparation or a selection change invalidated this one; callers ignore it.
    case superseded
}

enum RefundActionAvailability {
    case available
    case unavailable
}

enum POSRefundProcessingError: LocalizedError, Equatable {
    case missingSelectedOrder
    case missingRefundPreparation
    case emptySelection
    case refundAlreadyInProgress

    var errorDescription: String? {
        switch self {
        case .missingSelectedOrder, .missingRefundPreparation:
            return NSLocalizedString(
                "pos.refund.processing.error.missingPreparation",
                value: "The refund could not be prepared. Please try again.",
                comment: "Error shown when POS tries to process a refund without prepared order refund data."
            )
        case .emptySelection:
            return NSLocalizedString(
                "pos.refund.processing.error.emptySelection",
                value: "Select at least one item to refund.",
                comment: "Error shown when POS tries to process a refund without selected refund items."
            )
        case .refundAlreadyInProgress:
            return NSLocalizedString(
                "pos.refund.processing.error.alreadyInProgress",
                value: "A refund is already in progress. Please wait for it to finish.",
                comment: "Error shown when POS tries to process a second refund while another refund is in progress."
            )
        }
    }
}

protocol POSRefundControllerProtocol {
    var selectableItems: [POSRefundSelectableItem] { get }
    var hasLoadedSelectableItems: Bool { get }
    var hasModifiedSelection: Bool { get }
    var reviewPreparationState: POSRefundReviewPreparationState { get }
    var requiresCardPresentRefund: Bool { get }
    func refundActionAvailability(for order: POSOrder?) -> RefundActionAvailability
    func preloadRefund(for order: POSOrder) async
    func startRefundFlow(for order: POSOrder) async -> StartRefundFlowResult
    func refreshRefundableItems() async -> StartRefundFlowResult
    func toggleItemSelection(at index: Int)
    func toggleAllItemsSelection()
    func clearSelection()
    func reset()
    func prepareReview() async -> POSRefundReviewPreparationResult
    func processRefund(reason: String?) async throws -> Int64
}

@Observable final class POSRefundController: POSRefundControllerProtocol {
    private(set) var selectableItems: [POSRefundSelectableItem] = []
    private(set) var hasModifiedSelection = false
    private(set) var reviewPreparationState: POSRefundReviewPreparationState = .idle

    private let refundSubmissionProcessor: POSRefundSubmissionProcessing
    private var order: POSOrder?
    private var preparation: POSRefundPreparation?
    private var reviewPreparationTask: Task<POSRefundReviewPreparationResult, Never>?
    private var isProcessingRefund = false

    init(refundSubmissionProcessor: POSRefundSubmissionProcessing) {
        self.refundSubmissionProcessor = refundSubmissionProcessor
    }

    @MainActor
    var requiresCardPresentRefund: Bool {
        preparation?.requiresCardPresentRefund ?? false
    }

    func refundActionAvailability(for order: POSOrder?) -> RefundActionAvailability {
        guard let order, order.status == .completed else {
            return .unavailable
        }
        return .available
    }

    // MARK: - Refund Item Selection

    @MainActor
    func preloadRefund(for order: POSOrder) async {
        guard refundActionAvailability(for: order) == .available else {
            return
        }
        await refundSubmissionProcessor.preloadRefund(for: order)
    }

    @MainActor
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

    @MainActor
    var hasLoadedSelectableItems: Bool {
        !selectableItems.isEmpty
    }

    @MainActor
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

    @MainActor
    func toggleItemSelection(at index: Int) {
        guard selectableItems.indices.contains(index) else { return }
        selectableItems[index].isSelected.toggle()
        hasModifiedSelection = true
        resetReviewPreparation()
    }

    @MainActor
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

    @MainActor
    func clearSelection() {
        selectableItems = []
        hasModifiedSelection = false
        resetReviewPreparation()
    }

    @MainActor
    func reset() {
        order = nil
        preparation = nil
        clearSelection()
    }

    // MARK: - Refund Review Data Preparation

    @MainActor
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

    @MainActor
    func resetReviewPreparation() {
        reviewPreparationTask?.cancel()
        reviewPreparationTask = nil
        reviewPreparationState = .idle
    }

    // MARK: - Refund Processing

    @MainActor
    func processRefund(reason: String?) async throws -> Int64 {
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
        return order.id
    }
}
