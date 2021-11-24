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
}
