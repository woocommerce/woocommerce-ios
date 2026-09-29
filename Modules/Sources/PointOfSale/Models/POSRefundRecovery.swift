import enum Yosemite.RefundAPIError

/// What the cashier can do about a failed refund.
///
/// The refund endpoints reject with deterministic validation errors, so repeating the same request
/// against the same order data fails identically. `refreshItems` reloads the order and its refunds
/// so the next selection is made against the true remaining quantities, and `dismiss` leaves only
/// the way out of the flow. `retry` is for failures that can pass on a second attempt, a network
/// error for example.
enum POSRefundRecovery: Equatable {
    case retry
    case refreshItems
    case dismiss
}

extension RefundAPIError {
    /// None of the mapped rejections are retryable: the store answers an identical request the
    /// same way every time, so the way out is a fresh item list or leaving the flow.
    var recovery: POSRefundRecovery {
        switch self {
        case .quantityExceedsRefundable,
             .lineItemAlreadyRefunded,
             .refundExceedsRemaining,
             .refundTotalExceedsLine:
            return .refreshItems
        case .orderNotRefundable:
            // Nothing on the order can be refunded any more, so there is no selection to recover
            // to. The preview and create paths route this to the terminal screen before the
            // recovery is read.
            return .dismiss
        case .invalidRefundAmount:
            // The amount we sent is malformed rather than too large, which a fresh list won't fix.
            return .dismiss
        }
    }
}
