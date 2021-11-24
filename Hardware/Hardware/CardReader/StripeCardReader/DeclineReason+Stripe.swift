/// Maps Stripes many decline codes to our decline reasons
/// See `https://stripe.com/docs/declines/codes`
///

import Foundation
import StripeTerminal

extension DeclineReason {
    init(with stripeDeclineCode: String) {
        let stripeDeclineCodeDictionary: Dictionary<DeclineReason, [String]> =
            [
                .temporary: [
                    "approve_with_id",
                    "issuer_not_available",
                    "processing_error",
                    "reenter_transaction",
                    "try_again_later",
                ],
                .fraud: [
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
                ],
                .generic: [
                    "generic_decline",
                    "no_action_taken",
                    "not_permitted",
                    "service_not_allowed",
                    "transaction_not_allowed"
                ],
                .invalidAccount: [
                    "invalid_account",
                    "new_account_information_available",
                ],
                .cardNotSupported: [
                    "card_not_supported",
                ],
                .currencyNotSupported: [
                    "currency_not_supported",
                ],
                .duplicateTransaction: [
                    "duplicate_transaction",
                ],
                .expiredCard: [
                    "expired_card",
                ],
                .incorrectPostalCode: [
                    "incorrect_zip",
                ],
                .insufficientFunds: [
                    "insufficient_funds",
                    "withdrawal_count_limit_exceeded",
                ],
                .invalidAmount: [
                    "invalid_amount",
                ],
                .pinRequired: [
                    "invalid_pin",
                    "offline_pin_required",
                    "online_or_offline_pin_required",
                ],
                .tooManyPinTries: [
                    "pin_try_exceeded",
                ],
                .testCard: [
                    "testmode_decline",
                ],
                .testModeLiveCard: [
                    "test_mode_live_card"
                ]
            ]

        self = stripeDeclineCodeDictionary.first(
            where: { pair in
                pair.value.contains(stripeDeclineCode)
            }
        )?.key ?? .unknown
    }
}
