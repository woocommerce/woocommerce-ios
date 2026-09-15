import Foundation
import enum Yosemite.OrderRefundEligibilityFailure
import struct Yosemite.POSOrder

enum StartRefundFlowResult: Equatable {
    case hasItemsToRefund
    case nothingToRefund
    case ineligible(OrderRefundEligibilityFailure)
    case failed
}

/// Observable UI state for the selection sheet while review preparation runs (button spinner and
/// inline preview error). The preparation's outcome is returned by `prepareRefundReview()` as a
/// `POSRefundReviewPreparationResult` instead of being published here.
enum POSRefundReviewPreparationState: Equatable {
    case idle
    case loading
    /// `message` carries the server's rejection copy when the preview failed with an actionable
    /// code (for example the order changed since the screen was loaded); `nil` shows the generic
    /// preview error copy. `recovery` is what the cashier is offered next to it.
    case previewError(message: String? = nil, recovery: POSRefundRecovery = .retry)
}

/// Outcome of `prepareRefundReview()`, returned directly to the caller.
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

extension POSOrder {
    var refundActionAvailability: RefundActionAvailability {
        status == .completed ? .available : .unavailable
    }
}

struct POSRefundSubmissionResult: Equatable {
    let refundedOrderID: Int64
}

enum POSRefundProcessingError: LocalizedError, Equatable {
    case missingSelectedOrder
    case missingRefundPreparation
    case emptySelection
    case refundAlreadyInProgress

    var errorDescription: String? {
        switch self {
        case .missingSelectedOrder, .missingRefundPreparation:
            return Localization.missingPreparation
        case .emptySelection:
            return Localization.emptySelection
        case .refundAlreadyInProgress:
            return Localization.alreadyInProgress
        }
    }

    private enum Localization {
        static let missingPreparation = NSLocalizedString(
            "pos.refund.processing.error.missingPreparation",
            value: "The refund could not be prepared. Please try again.",
            comment: "Error shown when POS tries to process a refund without prepared order refund data."
        )
        static let emptySelection = NSLocalizedString(
            "pos.refund.processing.error.emptySelection",
            value: "Select at least one item to refund.",
            comment: "Error shown when POS tries to process a refund without selected refund items."
        )
        static let alreadyInProgress = NSLocalizedString(
            "pos.refund.processing.error.alreadyInProgress",
            value: "A refund is already in progress. Please wait for it to finish.",
            comment: "Error shown when POS tries to process a second refund while another refund is in progress."
        )
    }
}
