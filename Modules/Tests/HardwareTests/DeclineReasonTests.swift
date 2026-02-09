import Testing
@testable import Hardware
import StripeTerminal

/// Tests the mapping between DeclineReason and Stripe's decline code Strings
struct `Decline Reason Tests` {
    @Test func `approve with id maps to temporary`() {
        let declineReason = DeclineReason(with: "approve_with_id")
        #expect(declineReason == .temporary)
    }

    @Test func `issuer not available maps to temporary`() {
        let declineReason = DeclineReason(with: "issuer_not_available")
        #expect(declineReason == .temporary)
    }

    @Test func `processing error maps to temporary`() {
        let declineReason = DeclineReason(with: "processing_error")
        #expect(declineReason == .temporary)
    }

    @Test func `reenter transaction maps to temporary`() {
        let declineReason = DeclineReason(with: "reenter_transaction")
        #expect(declineReason == .temporary)
    }

    @Test func `try again later maps to temporary`() {
        let declineReason = DeclineReason(with: "try_again_later")
        #expect(declineReason == .temporary)
    }

    @Test func `call issuer maps to fraud`() {
        let declineReason = DeclineReason(with: "call_issuer")
        #expect(declineReason == .fraud)
    }

    @Test func `card velocity exceeded maps to fraud`() {
        let declineReason = DeclineReason(with: "card_velocity_exceeded")
        #expect(declineReason == .fraud)
    }

    @Test func `do not honor to fraud`() {
        let declineReason = DeclineReason(with: "do_not_honor")
        #expect(declineReason == .fraud)
    }

    @Test func `do not try again maps to fraud`() {
        let declineReason = DeclineReason(with: "do_not_try_again")
        #expect(declineReason == .fraud)
    }

    @Test func `fraudulent maps to fraud`() {
        let declineReason = DeclineReason(with: "fraudulent")
        #expect(declineReason == .fraud)
    }

    @Test func `lost card maps to fraud`() {
        let declineReason = DeclineReason(with: "lost_card")
        #expect(declineReason == .fraud)
    }

    @Test func `merchant blacklist maps to fraud`() {
        let declineReason = DeclineReason(with: "merchant_blacklist")
        #expect(declineReason == .fraud)
    }

    @Test func `pickup card maps to fraud`() {
        let declineReason = DeclineReason(with: "pickup_card")
        #expect(declineReason == .fraud)
    }

    @Test func `restricted card maps to fraud`() {
        let declineReason = DeclineReason(with: "restricted_card")
        #expect(declineReason == .fraud)
    }

    @Test func `revocation of all authorizations maps to fraud`() {
        let declineReason = DeclineReason(with: "revocation_of_all_authorizations")
        #expect(declineReason == .fraud)
    }

    @Test func `revocation of authorization maps to fraud`() {
        let declineReason = DeclineReason(with: "revocation_of_authorization")
        #expect(declineReason == .fraud)
    }

    @Test func `security violation maps to fraud`() {
        let declineReason = DeclineReason(with: "security_violation")
        #expect(declineReason == .fraud)
    }

    @Test func `stolen card maps to fraud`() {
        let declineReason = DeclineReason(with: "stolen_card")
        #expect(declineReason == .fraud)
    }

    @Test func `stop payment order maps to fraud`() {
        let declineReason = DeclineReason(with: "stop_payment_order")
        #expect(declineReason == .fraud)
    }

    @Test func `generic decline maps to generic`() {
        let declineReason = DeclineReason(with: "generic_decline")
        #expect(declineReason == .generic)
    }

    @Test func `no action taken maps to generic`() {
        let declineReason = DeclineReason(with: "no_action_taken")
        #expect(declineReason == .generic)
    }

    @Test func `not permitted maps to generic`() {
        let declineReason = DeclineReason(with: "not_permitted")
        #expect(declineReason == .generic)
    }

    @Test func `service not allowed maps to generic`() {
        let declineReason = DeclineReason(with: "service_not_allowed")
        #expect(declineReason == .generic)
    }

    @Test func `new account information available maps to generic`() {
        let declineReason = DeclineReason(with: "generic_decline")
        #expect(declineReason == .generic)
    }

    @Test func `transaction not allowed maps to generic`() {
        let declineReason = DeclineReason(with: "transaction_not_allowed")
        #expect(declineReason == .generic)
    }

    @Test func `invalid account maps to invalidAccount`() {
        let declineReason = DeclineReason(with: "invalid_account")
        #expect(declineReason == .invalidAccount)
    }

    @Test func `new account information available maps to invalidAccount`() {
        let declineReason = DeclineReason(with: "new_account_information_available")
        #expect(declineReason == .invalidAccount)
    }

    @Test func `card not supported maps to cardNotSupported`() {
        let declineReason = DeclineReason(with: "card_not_supported")
        #expect(declineReason == .cardNotSupported)
    }

    @Test func `currency not supported maps to currencyNotSupported`() {
        let declineReason = DeclineReason(with: "currency_not_supported")
        #expect(declineReason == .currencyNotSupported)
    }

    @Test func `duplicate transaction maps to duplicateTransaction`() {
        let declineReason = DeclineReason(with: "duplicate_transaction")
        #expect(declineReason == .duplicateTransaction)
    }

    @Test func `expired card maps to expiredCard`() {
        let declineReason = DeclineReason(with: "expired_card")
        #expect(declineReason == .expiredCard)
    }

    @Test func `incorrect zip maps to incorrectPostalCode`() {
        let declineReason = DeclineReason(with: "incorrect_zip")
        #expect(declineReason == .incorrectPostalCode)
    }

    @Test func `insufficient funds maps to insufficientFunds`() {
        let declineReason = DeclineReason(with: "insufficient_funds")
        #expect(declineReason == .insufficientFunds)
    }

    @Test func `withdrawal count limit exceeded maps to insufficientFunds`() {
        let declineReason = DeclineReason(with: "withdrawal_count_limit_exceeded")
        #expect(declineReason == .insufficientFunds)
    }

    @Test func `invalid amount maps to invalidAmount`() {
        let declineReason = DeclineReason(with: "invalid_amount")
        #expect(declineReason == .invalidAmount)
    }

    @Test func `invalid pin maps to pinRequired`() {
        let declineReason = DeclineReason(with: "invalid_pin")
        #expect(declineReason == .pinRequired)
    }

    @Test func `offline pin required maps to pinRequired`() {
        let declineReason = DeclineReason(with: "offline_pin_required")
        #expect(declineReason == .pinRequired)
    }

    @Test func `online or offline pin required maps to pinRequired`() {
        let declineReason = DeclineReason(with: "online_or_offline_pin_required")
        #expect(declineReason == .pinRequired)
    }

    @Test func `pin try exceeded maps to tooManyPinTries`() {
        let declineReason = DeclineReason(with: "pin_try_exceeded")
        #expect(declineReason == .tooManyPinTries)
    }

    @Test func `testmode decline maps to testCard`() {
        let declineReason = DeclineReason(with: "testmode_decline")
        #expect(declineReason == .testCard)
    }

    @Test func `test mode live card decline maps to testModeLiveCard`() {
        let declineReason = DeclineReason(with: "test_mode_live_card")
        #expect(declineReason == .testModeLiveCard)
    }

    @Test func `empty decline code maps to unknown`() {
        let declineReason = DeclineReason(with: "")
        #expect(declineReason == .unknown)
    }
}
