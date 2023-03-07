import Foundation

/// Determines whether the user should be allowed to retry a Stripe refund after a failure
///
struct ShouldRetryStripeRefundAfterFailureDeterminer {
    /// Returns whether the user should be allowed to retry a Stripe refund after a failure
    ///
    /// - Parameters:
    ///     - stripeFailureReason: the previous error failure reason
    ///
    /// - Returns: `true` if they can retry, `false` otherwise
    ///
    public func shouldRetryRefund(after stripeFailureReason: String?) -> Bool {
        guard let stripeFailureReason = stripeFailureReason else {
            return false
        }
        switch DeclineReason(with: stripeFailureReason) {
        case .fraud,
                .invalidAccount,
                .currencyNotSupported,
                .duplicateTransaction,
                .incorrectPostalCode,
                .invalidAmount:
            return false
        case .temporary,
                .generic,
                .insufficientFunds,
                .pinRequired,
                .tooManyPinTries,
                .testCard,
                .testModeLiveCard,
                .expiredCard,
                .cardNotSupported,
                .unknown:
            return true
        }
    }
}
