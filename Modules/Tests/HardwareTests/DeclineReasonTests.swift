import Testing
@testable import Hardware
import StripeTerminal

/// Tests the mapping between DeclineReason and Stripe's decline code Strings
@Suite("Decline Reason Tests")
struct DeclineReasonTests {
    @Test func test_approve_with_id_maps_to_temporary() {
        let declineReason = DeclineReason(with: "approve_with_id")
        #expect(declineReason == .temporary)
    }

    @Test func test_issuer_not_available_maps_to_temporary() {
        let declineReason = DeclineReason(with: "issuer_not_available")
        #expect(declineReason == .temporary)
    }

    @Test func test_processing_error_maps_to_temporary() {
        let declineReason = DeclineReason(with: "processing_error")
        #expect(declineReason == .temporary)
    }

    @Test func test_reenter_transaction_maps_to_temporary() {
        let declineReason = DeclineReason(with: "reenter_transaction")
        #expect(declineReason == .temporary)
    }

    @Test func test_try_again_later_maps_to_temporary() {
        let declineReason = DeclineReason(with: "try_again_later")
        #expect(declineReason == .temporary)
    }

    @Test func test_call_issuer_maps_to_fraud() {
        let declineReason = DeclineReason(with: "call_issuer")
        #expect(declineReason == .fraud)
    }

    @Test func test_card_velocity_exceeded_maps_to_fraud() {
        let declineReason = DeclineReason(with: "card_velocity_exceeded")
        #expect(declineReason == .fraud)
    }

    @Test func test_do_not_honor_to_fraud() {
        let declineReason = DeclineReason(with: "do_not_honor")
        #expect(declineReason == .fraud)
    }

    @Test func test_do_not_try_again_maps_to_fraud() {
        let declineReason = DeclineReason(with: "do_not_try_again")
        #expect(declineReason == .fraud)
    }

    @Test func test_fraudulent_maps_to_fraud() {
        let declineReason = DeclineReason(with: "fraudulent")
        #expect(declineReason == .fraud)
    }

    @Test func test_lost_card_maps_to_fraud() {
        let declineReason = DeclineReason(with: "lost_card")
        #expect(declineReason == .fraud)
    }

    @Test func test_merchant_blacklist_maps_to_fraud() {
        let declineReason = DeclineReason(with: "merchant_blacklist")
        #expect(declineReason == .fraud)
    }

    @Test func test_pickup_card_maps_to_fraud() {
        let declineReason = DeclineReason(with: "pickup_card")
        #expect(declineReason == .fraud)
    }

    @Test func test_restricted_card_maps_to_fraud() {
        let declineReason = DeclineReason(with: "restricted_card")
        #expect(declineReason == .fraud)
    }

    @Test func test_revocation_of_all_authorizations_maps_to_fraud() {
        let declineReason = DeclineReason(with: "revocation_of_all_authorizations")
        #expect(declineReason == .fraud)
    }

    @Test func test_revocation_of_authorization_maps_to_fraud() {
        let declineReason = DeclineReason(with: "revocation_of_authorization")
        #expect(declineReason == .fraud)
    }

    @Test func test_security_violation_maps_to_fraud() {
        let declineReason = DeclineReason(with: "security_violation")
        #expect(declineReason == .fraud)
    }

    @Test func test_stolen_card_maps_to_fraud() {
        let declineReason = DeclineReason(with: "stolen_card")
        #expect(declineReason == .fraud)
    }

    @Test func test_stop_payment_order_maps_to_fraud() {
        let declineReason = DeclineReason(with: "stop_payment_order")
        #expect(declineReason == .fraud)
    }

    @Test func test_generic_decline_maps_to_generic() {
        let declineReason = DeclineReason(with: "generic_decline")
        #expect(declineReason == .generic)
    }

    @Test func test_no_action_taken_maps_to_generic() {
        let declineReason = DeclineReason(with: "no_action_taken")
        #expect(declineReason == .generic)
    }

    @Test func test_not_permitted_maps_to_generic() {
        let declineReason = DeclineReason(with: "not_permitted")
        #expect(declineReason == .generic)
    }

    @Test func test_service_not_allowed_maps_to_generic() {
        let declineReason = DeclineReason(with: "service_not_allowed")
        #expect(declineReason == .generic)
    }

    @Test func test_new_account_information_available_maps_to_generic() {
        let declineReason = DeclineReason(with: "generic_decline")
        #expect(declineReason == .generic)
    }

    @Test func test_transaction_not_allowed_maps_to_generic() {
        let declineReason = DeclineReason(with: "transaction_not_allowed")
        #expect(declineReason == .generic)
    }

    @Test func test_invalid_account_maps_to_invalidAccount() {
        let declineReason = DeclineReason(with: "invalid_account")
        #expect(declineReason == .invalidAccount)
    }

    @Test func test_new_account_information_available_maps_to_invalidAccount() {
        let declineReason = DeclineReason(with: "new_account_information_available")
        #expect(declineReason == .invalidAccount)
    }

    @Test func test_card_not_supported_maps_to_cardNotSupported() {
        let declineReason = DeclineReason(with: "card_not_supported")
        #expect(declineReason == .cardNotSupported)
    }

    @Test func test_currency_not_supported_maps_to_currencyNotSupported() {
        let declineReason = DeclineReason(with: "currency_not_supported")
        #expect(declineReason == .currencyNotSupported)
    }

    @Test func test_duplicate_transaction_maps_to_duplicateTransaction() {
        let declineReason = DeclineReason(with: "duplicate_transaction")
        #expect(declineReason == .duplicateTransaction)
    }

    @Test func test_expired_card_maps_to_expiredCard() {
        let declineReason = DeclineReason(with: "expired_card")
        #expect(declineReason == .expiredCard)
    }

    @Test func test_incorrect_zip_maps_to_incorrectPostalCode() {
        let declineReason = DeclineReason(with: "incorrect_zip")
        #expect(declineReason == .incorrectPostalCode)
    }

    @Test func test_insufficient_funds_maps_to_insufficientFunds() {
        let declineReason = DeclineReason(with: "insufficient_funds")
        #expect(declineReason == .insufficientFunds)
    }

    @Test func test_withdrawal_count_limit_exceeded_maps_to_insufficientFunds() {
        let declineReason = DeclineReason(with: "withdrawal_count_limit_exceeded")
        #expect(declineReason == .insufficientFunds)
    }

    @Test func test_invalid_amount_maps_to_invalidAmount() {
        let declineReason = DeclineReason(with: "invalid_amount")
        #expect(declineReason == .invalidAmount)
    }

    @Test func test_invalid_pin_maps_to_pinRequired() {
        let declineReason = DeclineReason(with: "invalid_pin")
        #expect(declineReason == .pinRequired)
    }

    @Test func test_offline_pin_required_maps_to_pinRequired() {
        let declineReason = DeclineReason(with: "offline_pin_required")
        #expect(declineReason == .pinRequired)
    }

    @Test func test_online_or_offline_pin_required_maps_to_pinRequired() {
        let declineReason = DeclineReason(with: "online_or_offline_pin_required")
        #expect(declineReason == .pinRequired)
    }

    @Test func test_pin_try_exceeded_maps_to_tooManyPinTries() {
        let declineReason = DeclineReason(with: "pin_try_exceeded")
        #expect(declineReason == .tooManyPinTries)
    }

    @Test func test_testmode_decline_maps_to_testCard() {
        let declineReason = DeclineReason(with: "testmode_decline")
        #expect(declineReason == .testCard)
    }

    @Test func test_test_mode_live_card_decline_maps_to_testModeLiveCard() {
        let declineReason = DeclineReason(with: "test_mode_live_card")
        #expect(declineReason == .testModeLiveCard)
    }

    @Test func test_empty_decline_code_maps_to_unknown() {
        let declineReason = DeclineReason(with: "")
        #expect(declineReason == .unknown)
    }
}
