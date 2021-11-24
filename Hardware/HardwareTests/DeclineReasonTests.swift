import XCTest
@testable import Hardware
import StripeTerminal

/// Tests the mapping between DeclineReason and Stripe's decline code Strings
///
final class DeclineReasonTests: XCTestCase {
    func test_approve_with_id_maps_to_temporary() {
        let declineReason = DeclineReason(with: "approve_with_id")
        XCTAssertEqual(declineReason, .temporary)
    }

    func test_issuer_not_available_maps_to_temporary() {
        let declineReason = DeclineReason(with: "issuer_not_available")
        XCTAssertEqual(declineReason, .temporary)
    }

    func test_processing_error_maps_to_temporary() {
        let declineReason = DeclineReason(with: "processing_error")
        XCTAssertEqual(declineReason, .temporary)
    }

    func test_reenter_transaction_maps_to_temporary() {
        let declineReason = DeclineReason(with: "reenter_transaction")
        XCTAssertEqual(declineReason, .temporary)
    }

    func test_try_again_later_maps_to_temporary() {
        let declineReason = DeclineReason(with: "try_again_later")
        XCTAssertEqual(declineReason, .temporary)
    }

    func test_call_issuer_maps_to_fraud() {
        let declineReason = DeclineReason(with: "call_issuer")
        XCTAssertEqual(declineReason, .fraud)
    }

    func test_card_velocity_exceeded_maps_to_fraud() {
        let declineReason = DeclineReason(with: "card_velocity_exceeded")
        XCTAssertEqual(declineReason, .fraud)
    }

    func test_do_not_honor_to_fraud() {
        let declineReason = DeclineReason(with: "do_not_honor")
        XCTAssertEqual(declineReason, .fraud)
    }

    func test_do_not_try_again_maps_to_fraud() {
        let declineReason = DeclineReason(with: "do_not_try_again")
        XCTAssertEqual(declineReason, .fraud)
    }

    func test_fraudulent_maps_to_fraud() {
        let declineReason = DeclineReason(with: "fraudulent")
        XCTAssertEqual(declineReason, .fraud)
    }

    func test_lost_card_maps_to_fraud() {
        let declineReason = DeclineReason(with: "lost_card")
        XCTAssertEqual(declineReason, .fraud)
    }

    func test_merchant_blacklist_maps_to_fraud() {
        let declineReason = DeclineReason(with: "merchant_blacklist")
        XCTAssertEqual(declineReason, .fraud)
    }

    func test_pickup_card_maps_to_fraud() {
        let declineReason = DeclineReason(with: "pickup_card")
        XCTAssertEqual(declineReason, .fraud)
    }

    func test_restricted_card_maps_to_fraud() {
        let declineReason = DeclineReason(with: "restricted_card")
        XCTAssertEqual(declineReason, .fraud)
    }

    func test_revocation_of_all_authorizations_maps_to_fraud() {
        let declineReason = DeclineReason(with: "revocation_of_all_authorizations")
        XCTAssertEqual(declineReason, .fraud)
    }

    func test_revocation_of_authorization_maps_to_fraud() {
        let declineReason = DeclineReason(with: "revocation_of_authorization")
        XCTAssertEqual(declineReason, .fraud)
    }

    func test_security_violation_maps_to_fraud() {
        let declineReason = DeclineReason(with: "security_violation")
        XCTAssertEqual(declineReason, .fraud)
    }

    func test_stolen_card_maps_to_fraud() {
        let declineReason = DeclineReason(with: "stolen_card")
        XCTAssertEqual(declineReason, .fraud)
    }

    func test_stop_payment_order_maps_to_fraud() {
        let declineReason = DeclineReason(with: "stop_payment_order")
        XCTAssertEqual(declineReason, .fraud)
    }

    func test_generic_decline_maps_to_generic() {
        let declineReason = DeclineReason(with: "generic_decline")
        XCTAssertEqual(declineReason, .generic)
    }

    func test_no_action_taken_maps_to_generic() {
        let declineReason = DeclineReason(with: "no_action_taken")
        XCTAssertEqual(declineReason, .generic)
    }

    func test_not_permitted_maps_to_generic() {
        let declineReason = DeclineReason(with: "not_permitted")
        XCTAssertEqual(declineReason, .generic)
    }

    func test_service_not_allowed_maps_to_generic() {
        let declineReason = DeclineReason(with: "service_not_allowed")
        XCTAssertEqual(declineReason, .generic)
    }

    func test_new_account_information_available_maps_to_generic() {
        let declineReason = DeclineReason(with: "generic_decline")
        XCTAssertEqual(declineReason, .generic)
    }

    func test_transaction_not_allowed_maps_to_generic() {
        let declineReason = DeclineReason(with: "transaction_not_allowed")
        XCTAssertEqual(declineReason, .generic)
    }

    func test_invalid_account_maps_to_invalidAccount() {
        let declineReason = DeclineReason(with: "invalid_account")
        XCTAssertEqual(declineReason, .invalidAccount)
    }

    func test_new_account_information_available_maps_to_invalidAccount() {
        let declineReason = DeclineReason(with: "new_account_information_available")
        XCTAssertEqual(declineReason, .invalidAccount)
    }

    func test_card_not_supported_maps_to_cardNotSupported() {
        let declineReason = DeclineReason(with: "card_not_supported")
        XCTAssertEqual(declineReason, .cardNotSupported)
    }

    func test_currency_not_supported_maps_to_currencyNotSupported() {
        let declineReason = DeclineReason(with: "currency_not_supported")
        XCTAssertEqual(declineReason, .currencyNotSupported)
    }

    func test_duplicate_transaction_maps_to_duplicateTransaction() {
        let declineReason = DeclineReason(with: "duplicate_transaction")
        XCTAssertEqual(declineReason, .duplicateTransaction)
    }

    func test_expired_card_maps_to_expiredCard() {
        let declineReason = DeclineReason(with: "expired_card")
        XCTAssertEqual(declineReason, .expiredCard)
    }

    func test_incorrect_zip_maps_to_incorrectPostalCode() {
        let declineReason = DeclineReason(with: "incorrect_zip")
        XCTAssertEqual(declineReason, .incorrectPostalCode)
    }

    func test_insufficient_funds_maps_to_insufficientFunds() {
        let declineReason = DeclineReason(with: "insufficient_funds")
        XCTAssertEqual(declineReason, .insufficientFunds)
    }

    func test_withdrawal_count_limit_exceeded_maps_to_insufficientFunds() {
        let declineReason = DeclineReason(with: "withdrawal_count_limit_exceeded")
        XCTAssertEqual(declineReason, .insufficientFunds)
    }

    func test_invalid_amount_maps_to_invalidAmount() {
        let declineReason = DeclineReason(with: "invalid_amount")
        XCTAssertEqual(declineReason, .invalidAmount)
    }

    func test_invalid_pin_maps_to_pinRequired() {
        let declineReason = DeclineReason(with: "invalid_pin")
        XCTAssertEqual(declineReason, .pinRequired)
    }

    func test_offline_pin_required_maps_to_pinRequired() {
        let declineReason = DeclineReason(with: "offline_pin_required")
        XCTAssertEqual(declineReason, .pinRequired)
    }

    func test_online_or_offline_pin_required_maps_to_pinRequired() {
        let declineReason = DeclineReason(with: "online_or_offline_pin_required")
        XCTAssertEqual(declineReason, .pinRequired)
    }

    func test_pin_try_exceeded_maps_to_tooManyPinTries() {
        let declineReason = DeclineReason(with: "pin_try_exceeded")
        XCTAssertEqual(declineReason, .tooManyPinTries)
    }

    func test_testmode_decline_maps_to_testCard() {
        let declineReason = DeclineReason(with: "testmode_decline")
        XCTAssertEqual(declineReason, .testCard)
    }

    func test_empty_decline_code_maps_to_unknown() {
        let declineReason = DeclineReason(with: "")
        XCTAssertEqual(declineReason, .unknown)
    }
}
