import struct Yosemite.Order

/// Result of a scan-to-pay verification poll.
enum POSScanToPayVerificationResult: Equatable {
    /// The order has been paid (datePaid is set, or status indicates payment received).
    case paid
    /// The order is still awaiting payment.
    case pending
}

/// Abstracts the act of asking the backend whether a scan-to-pay payment has cleared.
/// Implementations typically reload the order and inspect `datePaid`/`status`.
protocol POSScanToPayVerifying {
    /// Returns the latest verification result, refreshing remote state.
    func checkPaymentStatus() async throws -> POSScanToPayVerificationResult
}
