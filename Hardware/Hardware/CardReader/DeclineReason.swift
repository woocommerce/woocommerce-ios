/// Defines the distint high level decline reasons we want to handle. Do NOT put
/// processor specific codes in this file. Use an extension to map
/// processor specific decline codes to these reasons.
///

import Foundation

enum DeclineReason {
    /// A possibly temporary error caused the decline (e.g. the issuing
    /// bank's servers could not be contacted.) Tell the user this and prompt
    /// them to try again with the same (or another) payment method.
    ///
    case temporary

    /// The card has been reported lost or stolen. Don't reveal this
    /// to the user. Just ask them to try another payment method.
    ///
    case fraud

    /// The card presented is not supported. Tell the user this and
    /// ask them to try another payment method.
    ///
    case cardNotSupported

    /// The currency is not supported by the card presented. Tell the
    /// user this and ask them to try another payment method.
    ///
    case currencyNotSupported

    /// An identical transaction was just completed for the card presented.
    /// Tell the user this and ask them to try another payment method if they
    /// really want to do this.
    ///
    case duplicateTransaction

    /// The card presented has expired. Tell the user this and ask them
    /// to try another payment method.
    ///
    case expiredCard

    /// The card presented has a different ZIP/postal code than was
    /// used to place the order. Tell the user this and ask them
    /// to try another payment method (or correct the order.)
    ///
    case incorrectPostalCode

    /// The card presented has insufficient funds for the purchase.
    /// Tell the user this and ask them to try another payment method.
    ///
    case insufficientFunds

    /// The card presented does not allow purchases of the amount
    /// given. Tell the user this and ask them to try another payment method.
    ///
    case invalidAmount

    /// The card presented requires a PIN and the device doesn't support
    /// PIN entry. Tell the user this and ask them to try another payment method.
    ///
    case pinRequired

    /// The card presented is a system test card and cannot be used to
    /// process a payment. Tell the user this and ask them to try another
    /// payment method.
    ///
    case testCard

    /// The card was declined for an unknown reason. Tell the user this and
    /// ask them to try another payment method.
    ///
    case unknown
}

extension DeclineReason {
    public var localizedDescription: String? {
        switch self {
        case .temporary:
            return NSLocalizedString("Trying again may succeed, or try another means of payment",
                                     comment: "Message when a card is declined due to a potentially temporary problem.")
        case .fraud:
            return NSLocalizedString("Try another means of payment",
                                     comment: "Message when a lost or stolen card is presented for payment. Do NOT disclose fraud.")
        case .cardNotSupported:
            return NSLocalizedString("The card does not support this type of purchase. Try another means of payment",
                                     comment: "Message when the card presented does not allow this type of purchase.")
        case .currencyNotSupported:
            return NSLocalizedString("The card does not support this currency. Try another means of payment",
                                     comment: "Message when the card presented does not support the order currency.")
        case .duplicateTransaction:
            return NSLocalizedString("An identical transaction was submitted recently. If you wish to continue, try another means of payment",
                                     comment: "Message when it looks like a duplicate transaction is being attempted.")
        case .expiredCard:
            return NSLocalizedString("The card has expired. Try another means of payment",
                                     comment: "Message when the presented card is past its expiration date.")
        case .incorrectPostalCode:
            return NSLocalizedString("The transaction postal code does not match that of the card presented. Correct the postal code or try another means of payment",
                                     comment: "Message when the presented card postal code doesn't match the order postal code.")
        case .insufficientFunds:
            return NSLocalizedString("Payment declined due to insufficient funds. Try another means of payment",
                                     comment: "Message when the presented card remaining credit or balance is insufficient for the purchase.")
        case .invalidAmount:
            return NSLocalizedString("The payment amount is not allowed for the card presented. Try another means of payment.",
                                     comment: "Message when the presented card does not allow the purchase amount.")
        case .pinRequired:
            return NSLocalizedString("This card requires a PIN code and thus cannot be processed. Try another means of payment",
                                     comment: "Message when a card requires a PIN code and we have no means of entering such a code.")
        case .testCard:
            return NSLocalizedString("System test cards are not permitted for payment. Try another means of payment",
                                     comment: "Message when attempting to pay for a live transaction with a test card.")
        case .unknown:
            return NSLocalizedString("Payment was declined for an unknown reason. Try another means of payment",
                                     comment: "Message when we don't know exactly why the payment was declined.")
        }
    }
}
