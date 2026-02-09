import Testing
@testable import Hardware

struct `Should Retry Stripe Refund After Failure Determiner Tests` {
    @Test func `shouldRetryRefund when failure reasons are not retryable returns false`() {
        let sut = ShouldRetryStripeRefundAfterFailureDeterminer()
        let nonRetryableFailureReasons = [
            "call_issuer",
            "card_velocity_exceeded",
            "do_not_honor",
            "do_not_try_again",
            "fraudulent",
            "lost_card",
            "merchant_blacklist",
            "pickup_card",
            "restricted_card",
            "revocation_of_all_authorizations",
            "revocation_of_authorization",
            "security_violation",
            "stolen_card",
            "stop_payment_order",
            "invalid_account",
            "new_account_information_available",
            "currency_not_supported",
            "duplicate_transaction",
            "incorrect_zip",
            "invalid_amount",
        ]

        for failureReason in nonRetryableFailureReasons {
            #expect(!sut.shouldRetryRefund(after: failureReason))
        }
    }

    @Test func `shouldRetryRefund when failure reasons are retryable returns true`() {
        let sut = ShouldRetryStripeRefundAfterFailureDeterminer()
        let retryableFailureReasons = [
            "approve_with_id",
            "issuer_not_available",
            "processing_error",
            "reenter_transaction",
            "try_again_later",
            "generic_decline",
            "no_action_taken",
            "not_permitted",
            "service_not_allowed",
            "transaction_not_allowed",
            "insufficient_funds",
            "withdrawal_count_limit_exceeded",
            "invalid_pin",
            "offline_pin_required",
            "online_or_offline_pin_required",
            "pin_try_exceeded",
            "testmode_decline",
            "test_mode_live_card",
            "expired_card",
            "card_not_supported",
        ]

        for failureReason in retryableFailureReasons {
            #expect(sut.shouldRetryRefund(after: failureReason))
        }
    }

    @Test func `shouldRetryRefund when failure reason is nil returns false`() {
        #expect(!ShouldRetryStripeRefundAfterFailureDeterminer().shouldRetryRefund(after: nil))
    }

    @Test func `shouldRetryRefund when failure reason is unknown returns true`() {
        #expect(ShouldRetryStripeRefundAfterFailureDeterminer().shouldRetryRefund(after: "not-a-stripe-error-for-sure"))
    }
}
